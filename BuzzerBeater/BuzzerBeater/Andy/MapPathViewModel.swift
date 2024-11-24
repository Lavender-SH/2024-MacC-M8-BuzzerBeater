//
//  MapPathViewModel.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/22/24.
//


import CoreLocation
import MapKit
import SwiftUI
import HealthKit


struct Segment {
    let id = UUID()
    let start: CLLocationCoordinate2D
    let end : CLLocationCoordinate2D
    let color : Color
}

class MapPathViewModel: ObservableObject {
   
    let healthStore =  HealthService.shared.healthStore
    let workoutManager = WorkoutManager.shared
    @Published  var region: MKCoordinateRegion?
    
    @Published var routePoints: [CLLocation] = []
    @Published var coordinates: [CLLocationCoordinate2D] = []
    @Published var velocities: [CLLocationSpeed] = []
    @Published var position: MapCameraPosition = .automatic
    
    @Published var activeEnergyBurned: Double = 0
    @Published var isDataLoaded : Bool = false
    @Published var isSegmentLoaded : Bool = false
    
    @Published var totalEnergyBurned: Double = 0
    @Published var totalDistance: Double = 0
    @Published var maxSpeed : Double = 0
    @Published var duration : TimeInterval = 0
    
    var minVelocity : Double = 0
    var maxVelocity: Double = 0
    var segments: [Segment] = []
    
    var workout: HKWorkout? // or the appropriate type for your workout data
    
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    
    func calculateColor(for velocity: Double, minVelocity: Double, maxVelocity: Double) -> Color {
       
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
    
    func computeSegments()  async  {
        let startIndex = 0
        let endIndexCount = min( self.coordinates.count , self.velocities.count)
        let interval = Int(endIndexCount / 1000) + 1
        let countOfArray  = Int( endIndexCount / interval )
        let endOfArrayIndex = countOfArray  - 2
        var countOfSegments = 0
        print("timestamp:\(Date()) count of array in compute segments: \(countOfArray) endIndex:\(endOfArrayIndex) endIndexCount :\(endIndexCount)")
        print("timestamp:\(Date()) mapPathviewModel.workout in the computeSegments  \(String(describing: self.workout?.uuid)) count: \(self.coordinates.count)")
        print("timestamp:\(Date()) isDataLoaded in the computeSegments:\(self.isDataLoaded) " )
        guard endOfArrayIndex  >= 0 else { return print("endIndexOfArray is less than or equal to 0") }
        
        var segments: [Segment] = Array(repeating: Segment(start: CLLocationCoordinate2D(latitude: 0, longitude: 0), end: CLLocationCoordinate2D(latitude: 0, longitude: 0), color: .clear), count: endOfArrayIndex + 2 )
        
        minVelocity = self.velocities.min() ?? 0
        maxVelocity =  self.velocities.max() ?? 0
        
        if minVelocity < 0  { minVelocity = 0  }
        if maxVelocity > 100 { maxVelocity = 100 }
        
        print("timestamp:\(Date()) computeSgments started. minVelocity: \(self.minVelocity) maxVelocity: \(self.maxVelocity)")
        let group = DispatchGroup()
        if endOfArrayIndex  <= 0 {
            return print("timestamp:\(Date()) endOfArrayIndex is less than or equal to 0")
        }
        
        for index in stride(from: startIndex, to: endIndexCount  - interval  - 1  ,  by: interval)  where index + interval < endIndexCount {
            
            guard index <= ( endIndexCount  -  interval - 1) else { return print("index is greater than endIndexCount \(index) \(endIndexCount - interval)") }

            let segmentQueue = DispatchQueue(label: "com.andy.segmentQueue")

            group.enter()
            DispatchQueue.main.async {
                let coordinate = self.coordinates[index]
                let nextCoordinate = self.coordinates[index + interval]
                
                let speed = (self.velocities[index] + self.velocities[index + interval]) / 2.0
                let color = self.calculateColor(for: speed, minVelocity: self.minVelocity, maxVelocity: self.maxVelocity)
                let segment = Segment(start: coordinate, end: nextCoordinate, color: color)
                
                // 이게 시간의 순서를 만족할까?
                // print("\(segment)")
                //  print("timestamp:\(Date()) index :\(index) count \(countOfSegments)")
                segments[countOfSegments] = segment
                countOfSegments += 1
                
                group.leave()
                
            }
            
        }
        
      
            group.notify(queue: DispatchQueue.main) {
                self.segments = segments.compactMap { $0 }
                self.isSegmentLoaded = true
                print("timestamp: \(Date()) segments count \(self.segments.count) isSegmentLoaded \(self.isSegmentLoaded)")
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
               
                }
                
                // 위치 데이터의 마지막 청크가 도착했을 때, 쿼리 정지 및 성공 콜백
                if done {
                    DispatchQueue.main.async {
                        self.healthStore.stop(routeLocationsQuery)
                        
                        self.routePoints.sort { (point1, point2) -> Bool in
                            return point1.timestamp < point2.timestamp
                        }
                        self.getMetric()  // 필요에 따라 정의된 메트릭 계산 함수 호출
                        
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
    
    
    func loadWorkoutData(workout: HKWorkout) async  {
        getRouteFrom(workout: workout) { success, error in
            if success {
                DispatchQueue.main.async {
                    
                    if self.workout != workout {
                        print("self.workout != workout in thre loadWorkoutData")
                        self.workout = workout
                    }
                    self.coordinates = self.routePoints.map { $0.coordinate }
                    self.velocities = self.routePoints.map { $0.speed }
                    print("timestamp:\(Date()) velocities:\(self.velocities.count), coordinates \(self.coordinates.count), routePoints: \(self.routePoints.count)  in the getRouteFrom")
                    self.duration = max(workout.endDate.timeIntervalSince(workout.startDate),workout.metadata?["TotalDuration"] as? Double ?? 0.0)
                    
                    self.totalDistance = workout.metadata?["TotalDistance"]  as? Double ?? 0.0
                    self.totalEnergyBurned = workout.metadata?["TotalEnergyBurned"] as? Double ?? 0.0
                    self.maxSpeed = workout.metadata?["MaxSpeed"] as? Double ?? 0.0
                    
                    self.workoutManager.fetchActiveEnergyBurned(startDate: workout.startDate, endDate: workout.endDate) { activeEnergyBurned in
                        if let activeEnergyBurned  = activeEnergyBurned{
                            DispatchQueue.main.async {
                                self.activeEnergyBurned = activeEnergyBurned.doubleValue(for: .kilocalorie())
                                print("activeEnergyBurned fetched successfully \(activeEnergyBurned)")
                            }
                            
                        } else {
                            print("activeEnergyBurned is nil")
                        }
                    }
                    
                    self.workoutManager.fetchTotalEnergyBurned(for: workout) { totalEnergyBurned in
                        if let totalEnergyBurned  = totalEnergyBurned{
                            DispatchQueue.main.async {
                                self.totalEnergyBurned = totalEnergyBurned.doubleValue(for: .kilocalorie())
                                print("totalEnergyBurned fetched successfully \(totalEnergyBurned)")
                            }
                        } else {
                            print("totalEnergyBurned is nil")
                        }
                    }
                    
                    self.isDataLoaded = true
                    
                    print("timestamp: \(Date()) isDataLoaded \(self.isDataLoaded)")
                }
            } else {
                DispatchQueue.main.async {
                    self.isDataLoaded  = false
                    print("timestamp \(Date()) loadWorkoutData error \(error?.localizedDescription ?? "unknown error") isDataLoaded: \(self.isDataLoaded)")
                }
            }
        }
    }
    
}
