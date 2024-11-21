//
//  MapPathView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/4/24.
//
import CoreLocation
import MapKit
import SwiftUI
import HealthKit

struct MapPathView: View {
    
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
    
    var isModal: Bool
    
    init(workout: HKWorkout, isModal: Bool = false) {
        self.workout = workout
        self.isModal = isModal
    }
    
    var body: some View {
        
        VStack{
            if isDataLoaded {
                ZStack(alignment: .top) {
                    
                    Map(position: $position, interactionModes: [.all] ){
                        if coordinates.count >= 2 {
                            ForEach(0..<coordinates.count - 1, id: \.self) { index in
                                let start = coordinates[index]
                                let end = coordinates[index + 1]
                                
                                let velocity = velocities[index]
                                let maxVelocity = velocities.max() ?? 10.0
                                let minVelocity = velocities.min() ?? 0.0
                                let color = calculateColor(for: velocity, minVelocity: minVelocity, maxVelocity: maxVelocity)
                                
                                MapPolyline(coordinates: [start, end])
                                    .stroke(color, lineWidth: 5)
                            }
                        }
                        
                        MapPolyline(coordinates: coordinates)
                            .stroke(Color.cyan, lineWidth: 1)
                        
                    }
                    .mapControls{
                        VStack{
                            MapUserLocationButton()
                            MapCompass()
                        }
                        
#if !os(watchOS)
                        MapScaleView()
#endif
                    }          .ignoresSafeArea(.all)
                    
                    
                    
                    //                    VStack{
                    //#if !os(watchOS)
                    //                        Text("\(formattedDuration(duration))").font(.caption2)
                    //                        Text("Total Distance: \(formattedDistance(totalDistance))")
                    //                            .font(.caption2)
                    //                        Text("Total Energy Burned: \(formattedEnergyBurned(totalEnergyBurned))")
                    //                            .font(.caption2)
                    //                        Text("MaxSpeed: \(maxSpeed) --  maxVelocity \(velocities.max() ?? 10)")
                    //                            .font(.caption2)
                    //
                    //#endif
                    //
                    //
                    //#if os(watchOS)
                    //                        Text("\(formattedDuration(duration))").font(.caption2)
                    //
                    //#endif
                    //
                    //                    }.padding(.top, 50)
                    if isModal {
                        VStack {
                            ZStack {
                                Button(action: {
                                    print("Button tapped!")
                                }) {
                                    Text("")
                                }
                                .frame(width: 300, height: 90)
                                .background(Color.gray.opacity(0.01))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white)
                                    .frame(width: 150, height: 5)
                            }
                            .padding(.top, -10)
                            
                            Spacer()
                        }

                    }
                }
            }
            
            else {
                //Text("Sky is Blue and Water is Clear!!!")
                ProgressView()
            }
            
        }
        .onAppear{
            // 실해은 순서되로 되나 뒤에 붙어있는 각각의 @esacping closure 들은 각기 다른 시점에 종료된다
            // swift thinking 이 필요함 비동기적 사고방식을 항상 염두에 둘것.시작은 같으나 각각 다른 시점에 종료되고 혹시 종료되는 시점이
            // 다음 시점의 프라세스에 영향을 줄것인가에 대한 고민.
            DispatchQueue.main.async{
                Task {
                    await loadWorkoutData()
                }
                
                self.totalDistance = workout.metadata?["TotalDistance"]  as? Double ?? 0.0
                self.duration = workout.metadata?["Duration"] as? Double ?? 0.0
                self.totalEnergyBurned =  workout.metadata?["TotalEnergyBurned"] as? Double ?? 0.0
                self.maxSpeed = workout.metadata?["MaxSpeed"] as? Double ?? 0.0
                
                self.workoutManager.fetchActiveEnergyBurned(startDate: workout.startDate, endDate: workout.endDate) { activeEnergyBurned in
                    if let activeEnergyBurned  = activeEnergyBurned{
                        self.activeEnergyBurned = activeEnergyBurned.doubleValue(for: .kilocalorie())
                        print("activeEnergyBurned fetched successfully \(activeEnergyBurned)")
                        
                    } else {
                        print("activeEnergyBurned is nil")
                    }
                }
                
                self.workoutManager.fetchTotalEnergyBurned(for: workout) { totalEnergyBurned in
                    if let totalEnergyBurned  = totalEnergyBurned{
                        self.totalEnergyBurned = totalEnergyBurned.doubleValue(for: .kilocalorie())
                        print("totalEnergyBurned fetched successfully \(totalEnergyBurned)")
                    } else {
                        print("totalEnergyBurned is nil")
                    }
                }
                self.duration = workout.endDate.timeIntervalSince(workout.startDate)
                
            }
            
        } .ignoresSafeArea()
        
    }
    
    func calculateColor(for velocity: Double, minVelocity: Double, maxVelocity: Double) -> Color {
        if maxVelocity <= minVelocity {
            return Color.green
        }
        let progress = CGFloat((velocity - minVelocity) / (maxVelocity - minVelocity))
        
        if progress < 0.7 {
            return Color.yellow
        }
        else if progress  >= 0.7 && progress < 0.85 {
            return Color.green
        }
        
        else if progress >= 0.85 {
            return Color.red
        }
        else {
            return Color.blue
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
    
    
}
