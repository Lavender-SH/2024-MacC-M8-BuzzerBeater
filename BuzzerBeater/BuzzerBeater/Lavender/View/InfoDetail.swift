//
//  InfoDetail.swift
//  BuzzerBeater
//
//  Created by 이승현 on 11/13/24.
//

import Foundation
import SwiftUI
import Charts
import MapKit
import HealthKit
import CoreLocation

struct InfoDetail: View {
    let workoutManager = WorkoutManager.shared
    
    var workout: HKWorkout // or the appropriate type for your workout data
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
    
    init(workout: HKWorkout) {
        self.workout = workout
        
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            
            HStack(spacing: 15) {
                InfoIcon()
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading) {
                    Text("Dinghy Yacht")
                        .font(.system(size: 25))
                        .padding(.bottom, 5)
                    if let startDate = startDate, let endDate = endDate {
                        Text("\(formattedTime(startDate)) - \(formattedTime(endDate))")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                        Text("Pohang City")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    
                    
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 25)
            
            
            
            
            List {
                Section(
                    header: HStack {
                        Text("Navigation Details")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                    }
                ) {
                    if isDataLoaded {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sailing Time")
                                Text(formattedDuration(duration))
                                    .font(.title)
                                    .foregroundColor(.yellow)
                                    .fontDesign(.rounded)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sailing Distance")
                                Text("\(formattedDistance(totalDistance))")
                                    .font(.title)
                                    .foregroundColor(.cyan)
                                    .fontDesign(.rounded)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Calories")
                                Text("\(formattedEnergyBurned(totalEnergyBurned))")
                                    .font(.title)
                                    .foregroundColor(.cyan)
                                    .fontDesign(.rounded)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Highest Speed")
                                Text("\(formattedMaxSpeed(velocities.max() ?? 0)) m/s")
                                    .font(.title)
                                    .foregroundColor(.cyan)
                                    .fontDesign(.rounded)
                            }
                        }
                        .padding()
                    } else {
                        ProgressView("Loading Data...")
                    }
                }
                .textCase(nil)
            }
            .onAppear {
                DispatchQueue.main.async {
                    Task {
                        await loadWorkoutData()
                    }
                    
                    self.totalDistance = workout.metadata?["TotalDistance"] as? Double ?? 0.0
                    self.duration = workout.metadata?["Duration"] as? Double ?? 0.0
                    self.totalEnergyBurned = workout.metadata?["TotalEnergyBurned"] as? Double ?? 0.0
                    self.maxSpeed = workout.metadata?["MaxSpeed"] as? Double ?? 0.0
                    self.startDate = workout.metadata?["StartDate"] as? Date ?? Date()
                    self.endDate = workout.metadata?["EndDate"] as? Date ?? Date()
                    
                    self.workoutManager.fetchActiveEnergyBurned(startDate: workout.startDate, endDate: workout.endDate) { activeEnergyBurned in
                        if let activeEnergyBurned = activeEnergyBurned {
                            self.activeEnergyBurned = activeEnergyBurned.doubleValue(for: .kilocalorie())
                            print("activeEnergyBurned fetched successfully \(activeEnergyBurned)")
                        } else {
                            print("activeEnergyBurned is nil")
                        }
                    }
                    
                    self.workoutManager.fetchTotalEnergyBurned(for: workout) { totalEnergyBurned in
                        if let totalEnergyBurned = totalEnergyBurned {
                            self.totalEnergyBurned = totalEnergyBurned.doubleValue(for: .kilocalorie())
                            print("totalEnergyBurned fetched successfully \(totalEnergyBurned)")
                        } else {
                            print("totalEnergyBurned is nil")
                        }
                    }
                    
                    self.duration = workout.endDate.timeIntervalSince(workout.startDate)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    
    func loadWorkoutData() async  {
        getRouteFrom(workout: workout) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.coordinates = self.routePoints.map { $0.coordinate }
                    self.velocities = self.routePoints.map { $0.speed }
                    self.isDataLoaded = true
                    print("velocities:\(self.velocities.count), coordinates \(self.coordinates.count), routePoints \(self.routePoints.count) in the getRouteFrom")
                }
            } else {
                DispatchQueue.main.async {
                    self.isDataLoaded = true
                    print("loadWorkoutData error \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
    
    public func getRouteFrom(workout: HKWorkout, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
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
                    self.getMetric()  // 필요에 따라 정의된 메트릭 계산 함수 호출
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
    func getMetric(){
        let latitudes = routePoints.map { $0.coordinate.latitude }
        let longitudes = routePoints.map { $0.coordinate.longitude }
        
        // Calculate the map region's boundaries
        guard let maxLat = latitudes.max(), let minLat = latitudes.min(),
              let maxLong = longitudes.max(), let minLong = longitudes.min() else {
            print("mapSpan error will happen!!!")
            return
        }
        let mapCenter = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLong + maxLong) / 2)
        let mapSpan = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * mapDisplayAreaPadding , self.minDegree), longitudeDelta: max((maxLong - minLong) * mapDisplayAreaPadding , self.minDegree))
        
        print("mapspan in MapPathView: \(mapSpan)")
        // Update the map region and plot the route on the main thread
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(center: mapCenter, span: mapSpan)
            // Stop the route locations query now that we're done
            if let region = self.region {
                self.position = .region(region)
            }
        }
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
        formatter.amSymbol = "Am"
        formatter.pmSymbol = "Pm"
        return formatter.string(from: date)
    }
    
}
