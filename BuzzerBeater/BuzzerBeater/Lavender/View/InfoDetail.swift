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
import Charts

struct InfoDetail: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isMapModalPresented = false
    let workoutManager = WorkoutManager.shared
    @State private var isHelpModalPresented = false
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
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        
        List {
            Section {
                HStack(spacing: 20) {
                    InfoIcon()
                        .frame(width: 80, height: 80)
                    
                    VStack(alignment: .leading) {
                        Text("Dinghy Yacht")
                            .font(.system(size: 25).bold())
                            .fontDesign(.rounded)
                            .padding(.bottom, 5)
                        if let startDate = startDate, let endDate = endDate {
                            Text("\(formattedTime(startDate)) - \(formattedTime(endDate))")
                                .font(.system(size: 20).bold())
                                .foregroundColor(.secondary)
                                .fontDesign(.rounded)
                                .padding(.bottom, 5)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                            //Text("Pohang City")
                            Text(locationName)
                                .font(.system(size: 18).bold())
                                .fontDesign(.rounded)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)
            }
            .listRowBackground(Color.clear)
            
            Section(
                header: Text("Navigation Details")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .textCase(nil)
            ) {
                if isDataLoaded {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 16) {
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
                    .padding(1)
                } else {
                    ProgressView("Loading Data...")
                }
            }
            
            Section(
                header: Text("Speed of a Yacht")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .fontDesign(.rounded)
                    .textCase(nil)
            ) {
                if isDataLoaded {
                    let startTime = routePoints.first?.timestamp ?? Date()
                    let endTime = routePoints.last?.timestamp ?? Date()
                    let totalDurationInSeconds = endTime.timeIntervalSince(startTime)
                    let averageSpeed = velocities.reduce(0, +) / Double(velocities.count)
                    
                    VStack(alignment: .leading, spacing: 8){
                        Text("Average Speed: \(String(format: "%.2f", averageSpeed)) m/s")
                            .font(.headline)
                            .fontDesign(.rounded)
                            .padding(.bottom, 8)
                            .foregroundStyle(.cyan)
                        Chart {
                            ForEach(Array(velocities.enumerated()), id: \.offset) { index, speed in
                                let timeInSeconds = routePoints[index].timestamp.timeIntervalSince(startTime)
                                LineMark(
                                    x: .value("Time (sec)", timeInSeconds),
                                    y: .value("Speed", speed)
                                )
                                .foregroundStyle(.cyan)
                            }
                        }                                    .frame(height: 130)
                            .chartXScale(domain: 0...totalDurationInSeconds)  // Dynamic x-axis based on total duration
                            .chartXAxis {
                                AxisMarks()
                            }
                    }
                }
            }
            
            Section(header: Text("Navigation Route")
                .font(.title3)
                .bold()
                .fontDesign(.rounded)
                .foregroundColor(.white)
                .textCase(nil)) {
                    // Button to show the map in a modal view
                    Button(action: {
                        isMapModalPresented = true // Present modal when tapped
                    }) {
                        MapPathView(workout: workout, isModal: false)
                            .frame(height: 250) 
                    }
                    .buttonStyle(PlainButtonStyle()) // Disable default button styling
                }
        }
        .padding(.top, -1)
        .sheet(isPresented: $isMapModalPresented) {
           
            MapPathView(workout: workout, isModal: true)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            DispatchQueue.main.async {
                Task {
                    if !self.isDataLoaded {
                        await loadWorkoutData()
                    }
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
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(formattedDate(startDate))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isHelpModalPresented.toggle() // Toggle the modal state
                    } label: {
                        Image(systemName: "info.circle")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $isHelpModalPresented) {
                HelpModalView()
        }
#endif
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
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    }
    private func formattedDate(_ date: Date?) -> String {
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
