//
//  WatchResultRecord.swift
//  BuzzerBeaterWatch Watch App
//
//  Created by 이승현 on 11/19/24.
//

import SwiftUI
import HealthKit
import CoreLocation
import MapKit

struct WatchResultRecord: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isMapModalPresented = false
    let workoutManager = WorkoutManager.shared
    
    var workout: HKWorkout
    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    @State private var region: MKCoordinateRegion?
    
    @State var routePoints: [CLLocation] = []
    @State var coordinates: [CLLocationCoordinate2D] = []
    @State var velocities: [CLLocationSpeed] = []
    @State var position: MapCameraPosition = .automatic
    
    @State var activeEnergyBurned: Double = 0
    @State var isDataLoaded : Bool = false
    
    
    @State var totalEnergyBurned: Double = 0
    @State var totalDistance: Double = 0
    @State var maxSpeed : Double = 0
    @State var duration : TimeInterval = 0
    @State var startDate: Date?
    @State var endDate: Date?
    @State var locationName: String = "Loading location..."
    
    init(workout: HKWorkout) {
        self.workout = workout
        
    }
    
    var body: some View {
        VStack(spacing: 8) { // 전체 줄 간격
            if isDataLoaded {
                // 날짜 표시
                Text(formattedDate(startDate))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // 상자 그룹
                HStack(spacing: 8) {
                    // Time 상자
                    InfoBox(title: "Time", value: formattedDuration(duration), valueColor: .yellow)
                    // Distance 상자
                    InfoBox(title: "Distance", value: "\(formattedDistance(totalDistance))", valueColor: .cyan)
                }
                HStack(spacing: 8) {
                    // Calories 상자
                    InfoBox(title: "Calories", value: "\(formattedEnergyBurned(totalEnergyBurned))", valueColor: .cyan)
                    // Max Speed 상자
                    InfoBox(title: "Max Speed", value: "\(formattedMaxSpeed(velocities.max() ?? 0)) m/s", valueColor: .cyan)
                }
                
                // 시작 및 종료 시간
                if let startDate = startDate, let endDate = endDate {
                    Text("\(formattedTime(startDate)) - \(formattedTime(endDate))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // 위치 정보
                HStack(spacing: 2) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(locationName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            } else {
                // 데이터 로딩 중 표시
                ProgressView("Loading Data...")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.async {
                Task {
                    await loadWorkoutData()
                }
                
                self.totalDistance = workout.metadata?["TotalDistance"] as? Double ?? 0.0
                self.duration = workout.metadata?["Duration"] as? Double ?? 0.0
                self.totalEnergyBurned = workout.metadata?["TotalEnergyBurned"] as? Double ?? 0.0
                self.maxSpeed = workout.metadata?["MaxSpeed"] as? Double ?? 0.0
                self.startDate = workout.startDate
                self.endDate = workout.endDate
                
                self.workoutManager.fetchActiveEnergyBurned(startDate: workout.startDate, endDate: workout.endDate) { activeEnergyBurned in
                    if let activeEnergyBurned = activeEnergyBurned {
                        self.activeEnergyBurned = activeEnergyBurned.doubleValue(for: .kilocalorie())
                    }
                }
                
                self.workoutManager.fetchTotalEnergyBurned(for: workout) { totalEnergyBurned in
                    if let totalEnergyBurned = totalEnergyBurned {
                        self.totalEnergyBurned = totalEnergyBurned.doubleValue(for: .kilocalorie())
                    }
                }
                
                self.duration = workout.endDate.timeIntervalSince(workout.startDate)
            }
        }
    }

    
    func loadWorkoutData() async  {
        getRouteFrom(workout: workout) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.coordinates = self.routePoints.map { $0.coordinate }
                    self.velocities = self.routePoints.map { $0.speed }
                    self.isDataLoaded = true
                    if let firstLocation = routePoints.first {
                        fetchLocationName(for: firstLocation)
                    }
                    print("velocities:\(self.velocities.count), coordinates \(self.coordinates.count), routePoints \(self.routePoints.count) in the getRouteFrom, 지역이름\(locationName)")
                }
            } else {
                DispatchQueue.main.async {
                    self.isDataLoaded = true
                    print("loadWorkoutData error \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
    

    func getRouteFrom(workout: HKWorkout, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        // Create a predicate for objects associated with the workout
        let runningObjectQuery = HKQuery.predicateForObjects(from: workout)
        
        // 1. `routeQuery`: Retrieve all workout route samples associated with the workout.
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (routeQuery, samples, deletedObjects, anchor, error) in
            
            // 오류가 발생하면 completion에 전달하고 함수 종료
            if let error = error {
                print("The initial query failed with error: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            // Route가 없으면 completion에 false 전달하고 함수 종료
            guard let route = samples?.first as? HKWorkoutRoute else {
                print("No route samples found.")
                completion(false, nil)
                return
            }
            
            // 2. `routeLocationsQuery`: Retrieve locations from the specific workout route.
            let routeLocationsQuery = HKWorkoutRouteQuery(route: route) { (routeLocationsQuery, locations, done, error) in
                
                // 오류 발생 시 completion에 전달하고 함수 종료
                if let error = error {
                    print("Error retrieving locations: \(error.localizedDescription)")
                    completion(false, error)
                    return
                }
                
                // 위치 데이터가 비어 있는 경우 completion 호출 후 종료
                guard let locations = locations else {
                    print("No locations found in route.")
                    completion(false, nil)
                    return
                }
                
                print("Locations count: \(locations.count)")
                
                // 위치 데이터를 저장하고 후속 작업을 수행
                DispatchQueue.main.async {
                    self.routePoints.append(contentsOf: locations)
                    //self.getMetric()  // 필요에 따라 정의된 메트릭 계산 함수 호출
                }
                
                // 위치 데이터의 마지막 청크가 도착했을 때, 쿼리 정지 및 성공 콜백
                if done {
                    DispatchQueue.main.async {
                        self.healthStore.stop(routeLocationsQuery)
                        completion(true, nil)
                    }
                }
            }
            
            // routeLocationsQuery 실행
            self.healthStore.execute(routeLocationsQuery)
        }
        
        // `routeQuery`가 업데이트되었을 때 처리
        routeQuery.updateHandler = { (routeQuery, samples, deleted, anchor, error) in
            if let error = error {
                print("Update query failed with error: \(error.localizedDescription)")
                return
            }
            // 필요 시 업데이트를 처리할 수 있습니다.
        }
        
        // routeQuery 실행
        healthStore.execute(routeQuery)
    }
    
    func fetchRouteData(workout: HKWorkout) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, _, _, error in
            guard let routes = samples as? [HKWorkoutRoute], error == nil else {
                print("Error fetching route data: \(String(describing: error))")
                return
            }
            
            let dispatchGroup = DispatchGroup()
            for route in routes {
                dispatchGroup.enter()
                let routeLocationsQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                    if let locations = locations {
                        self.velocities.append(contentsOf: locations.map { $0.speed })
                    }
                    if done || error != nil {
                        dispatchGroup.leave()
                    }
                }
                self.healthStore.execute(routeLocationsQuery)
            }
            
            dispatchGroup.notify(queue: .main) {
                self.maxSpeed = self.velocities.max() ?? 0
                self.isDataLoaded = true
            }
        }
        self.healthStore.execute(routeQuery)
    }
    
    
    
    
    
    
    
    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func formattedDistance(_ distance: Double?) -> String {
        // distance가 nil이 아니면, 미터 단위로 값을 가져와서 킬로미터로 변환
        guard let distance = distance else { return "0.00 km" }
        
        // 미터 단위로 값을 가져온 후, 1000으로 나누어 킬로미터로 변환
        let kilometer = distance / 1000
        
        print("kilo: \(kilometer)")
        // 킬로미터 단위로 포맷팅해서 반환
        return String(format: "%.2f km", kilometer)
    }
    
    func formattedEnergyBurned(_ calories: Double?) -> String {
        // distance가 nil이 아니면, 미터 단위로 값을 가져와서 킬로미터로 변환
        guard let calories = calories else { return "0.00 Kcal" }
        let caloriesInt = Int( calories )
        print("Kcal \(caloriesInt)")
        // 킬로미터 단위로 포맷팅해서 반환
        return String(format: "%d Kcal", caloriesInt)
    }
    
    func formattedMaxSpeed(_ speed: CLLocationSpeed) -> String {
        return String(format: "%.1f", speed)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    }
    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd (EEE)"
        return formatter.string(from: date)
    }
    
    func fetchLocationName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "en_US")) { placemarks, error in
            if let placemark = placemarks?.first, let city = placemark.locality {
                self.locationName = city
            } else {
                self.locationName = "Unknown Location"
            }
        }
    }
}

struct WatchResultRecord_Previews: PreviewProvider {
    static var previews: some View {
        WatchResultRecord(
            workout: createDummyWorkout()
        )
    }
    
    static func createDummyWorkout() -> HKWorkout {
        // 더미 HKWorkout 객체 생성
        return HKWorkout(
            activityType: .sailing,
            start: Date(),
            end: Date().addingTimeInterval(3600),
            workoutEvents: nil,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 500),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: 10000),
            metadata: [
                "TotalDistance": 10000.0,
                "TotalEnergyBurned": 500.0
            ]
        )
    }
}


struct InfoBox: View {
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.darkGray).opacity(0.3))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
        )
    }
}
