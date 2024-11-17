//
//  WorkoutManager.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/30/24.
//
import CoreLocation
import HealthKit
import Foundation
import SwiftUI
import Combine


struct metadataForRouteDataPoint: Equatable, Identifiable, Codable{
    var id: UUID = UUID()
    var timeStamp: Date
    var boatHeading : Double?
    var windSpeed: Double  // m/s
    var windDirection: Double?  //deg
    var windAdjustedDirection : Double?
}




class WorkoutManager:  ObservableObject
{
    static let shared = WorkoutManager()
    let locationManager = LocationManager.shared
    let windDetector = WindDetector.shared
    let healthService = HealthService.shared
    let healthStore = HealthService.shared.healthStore
   
    var workout: HKWorkout?
    //   var workoutBuilder: HKWorkoutBuilder?
    var liveWorkoutBuilder: HKLiveWorkoutBuilder?
    var workoutSession: HKWorkoutSession?
    var workoutRouteBuilder: HKWorkoutRouteBuilder?
    
    // for later use
    var appIdentifier: String?
    var routeIdentifier: String?
    
    var isWorkoutActive: Bool = false
    var lastHeading: CLHeading?
    
   
    var metadataForWorkout: [String: Any] = [:] // AppIdentifier, 날짜,
    var metadataForRoute: [String: Any] = [:]   // RouteIdentifer, timeStamp, WindDirection, WindSpeed
    var metadataForRouteDataPointArray : [metadataForRouteDataPoint] = []
    let routeDataQueue = DispatchQueue(label: "com.lavender.buzzbeater.routeDataQueue")
    // endTime은 3시간 이내로 제한 즉 한세션의 최대 크기를 제한하도록 함. 나중에 사용예정
    var startDate: Date?
    var endDate : Date?
    var previousLocation: CLLocation?
    var totalDistance: Double = 0
    var totalEnergyBurned : Double = 0
    var activeEnergyBurned : Double = 0
    
    var cancellables: Set<AnyCancellable> = []
    private let locationChangeThreshold: CLLocationDistance = 10.0 // 10 meters
    private let headingChangeThreshold: CLLocationDegrees = 15.0   // 15 degrees
    private let timeIntervalForRoute = TimeInterval(10)
    private let timeIntervalForWind = TimeInterval(60*30)
    var maxSpeed : Double = 0
    
    deinit {
           cancellables.removeAll() // 모든 구독 해제
           print("Workout deinitialized")
       }
    func startWorkout(startDate: Date)  {
        // 운동을 시작하기 전에 HKWorkoutBuilder를 초기화
        if isWorkoutActive  { return }
        isWorkoutActive = true
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .sailing
        workoutConfiguration.locationType = .outdoor
        
        
        do {
            workoutSession = try  HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        } catch {
            print("Error creating workout session: \(error.localizedDescription)")
        }
        
        guard let workoutSession = workoutSession else {
            print("workoutSession may be nil ")
            return }
        
        liveWorkoutBuilder = workoutSession.associatedWorkoutBuilder()
        
      
        guard let liveWorkoutBuilder = liveWorkoutBuilder else {
            print("liveWorkoutBuilder may be nil ")
            return }
        liveWorkoutBuilder.dataSource =  HKLiveWorkoutDataSource(healthStore: healthStore,
                                                                 workoutConfiguration: workoutConfiguration)
        print("workoutSession: \(String(describing: workoutSession)) liveworkoutBuilder: \(liveWorkoutBuilder.debugDescription) created succesfully")
        
        
        
        workoutRouteBuilder =  HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
        
        workoutSession.startActivity(with:startDate)
        
        liveWorkoutBuilder.beginCollection(withStart: startDate) { (success, error) in
            if success {
                print("Started collecting live workout dat from  ")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.startTimer()
                }
            } else {
                print("Error starting live workout collection: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func collectData(startDate: Date, endDate: Date,  metadataForWorkout: [String: Any]) {
        // 데이터 수집 예시
        
        guard let liveWorkoutBuilder = self.liveWorkoutBuilder,
              //Apple Watch에서는 workoutBuilder 와 liveWorkoutBuilder를 어떻게 사용할지 명확하지 않지만 현재는 liveWorkoutBuilder로 충분함.
              //let workoutBuilder = self.workoutBuilder,
                let workoutSession = self.workoutSession else {
            print("liveWorkoutBuilder, workoutSession maybe nil ")
            return
        }
        
        
        // workoutSession.end()가  finishWorkout보다 먼저 실행되어야 하는데  finishWorkout()안에서 같이 처리하기로함.
        // Apple  공식문서에  session.end()를 build.endCollection보다 먼저 실행함
        //https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/running_workout_sessions
        
        // updateWorkoutDistance should be proceesed before workoutBuilder.finishWorkout
        
        Task{
            if let startDate = self.startDate, let endDate = self.endDate {
                await withCheckedContinuation { continuation in
                    self.updateWorkoutDistance(startDate: startDate, endDate: endDate, self.totalDistance) { (success, error) in
                        if success {
                            print("Completion: Distance update was successful.")
                            continuation.resume()
                        } else if let error = error {
                            print("Completion: Error encountered - \(error)")
                            continuation.resume()
                        } else {
                            print("Completion: Unknown error occurred.")
                            continuation.resume()
                        }
                        // 추가 로직을 수행하거나 이 흐름을 종료
                    }
                }
                
                
            } else {
                print("startDate or endDate is nil")
            }
        }
      

        liveWorkoutBuilder.addMetadata(metadataForWorkout) { (success, error) in
            if success {
                print("metadataForWorkout : \(liveWorkoutBuilder.metadata)")
            } else {
                print("Error adding metadata: \(error?.localizedDescription ?? "Unknown error")")
            }
            
            // Regardless of success or failure, finish the workout
            Task {
                await self.finishWorkoutAsync(endDate: endDate, metadataForWorkout: self.metadataForWorkout)
            }
        }
    
    }
    
   
    
    // async 버전으로 만들고  await 을사용해서 모든 비동기호출을 마치고 종료할수있도록 함
    // try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>)
    // let workout = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKWorkout, Error>)
    
    // workoutBuilder 대신에  liveWorkoutBuilder를 사용함
    // Apple  공식문서에  session.end()를 build.endCollection보다 먼저 실행함
    //https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/running_workout_sessions
    // 종료 순서가 중요함
    // 1.workoutSession을 가장 먼저 종료
    // 2.liveWorkoutBuilder?.endCollection 을 함
    // 3.liveWorkoutBuilder?.finishWorkout
    // 4.workoutRouteBuilder.finishRoute
    // Apple  공식문서에  session.end()를 build.endCollection보다 먼저 실행함
    
    func finishWorkoutAsync(endDate: Date, metadataForWorkout: [String: Any]?) async {
        if !isWorkoutActive {
            print("Workout is not active \(isWorkoutActive)")
            return
        }
        DispatchQueue.main.async {
            self.isWorkoutActive = false
        
        }
        guard let liveWorkoutBuilder = self.liveWorkoutBuilder,
              let workoutSession = self.workoutSession else {
            print("liveWorkoutBuilder or workoutSession is nil")
            return
        }
        // workoutSession이 먼저 종료되어야 한다고 공식문서에 되있음.
        print("Ending workout session: \(workoutSession) liveWorkoutBuilder \(liveWorkoutBuilder.allStatistics)")
        
        workoutSession.end()
        
        do {
            print("workoutSession.state.rawValue \(workoutSession.state.rawValue)")
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                liveWorkoutBuilder.endCollection(withEnd: endDate) { success, error in
                    if let error = error {
                        print("endCollection Error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        print("Workout endCollection at \(endDate)")
                        continuation.resume()
                    }
                }
            }
            
            let workout = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKWorkout, Error>) in
                liveWorkoutBuilder.finishWorkout { workout, error in
                    if let error = error {
                        print("finishWorkout Error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else if let workout = workout {
                        self.workout = workout
                        DispatchQueue.main.async{
                            print("workout in the finishWorkoutAsync: \(workout)")
                            print("lastActivity in the finishWorkoutAsync: \(String(describing: workout.workoutActivities.last))")
                            print("Preparing to finish route with workout: \(workout)  " )
                            if let metadata = workout.metadata {
                                for (key, value) in metadata {
                                    print("\(key): \(value)")
                                }
                            }
                            print("metadata: \(String(describing: self.metadataForRoute))")
                            self.updateWorkoutDistance(self.totalDistance )
                        }
                        continuation.resume(returning: workout)  // Resume continuation after workout is finalized
                    } else {
                        print("finishWorkout Error: No workout returned from finishWorkout")
                        continuation.resume(throwing: HealthKitError.unknownError)
                    }
                }
            }
            
            Task {
              //  self.printWorkoutActivityType(workout: workout)
                self.metadataForRoute = self.makeMetadataForRoute(
                    routeIdentifier: "seastheDayroute",
                    metadataForRouteDataPointArray: self.metadataForRouteDataPointArray
                )
                let routeResult = await self.finishRoute(workout: workout, metadataForRoute: self.metadataForRoute)
                switch routeResult {
                case .success(let route):
                    print("Successfully finished route. Workout UUID: \(workout.uuid), Route UUID: \(route.uuid)")
                case .failure(let error):
                    print("Failed to finish route with error: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print("An error occurred while finishing the workout: \(error.localizedDescription)")
        }
    }
    
    func updateWorkoutDistance(_ distanceInMeters: Double) {
        guard let builder = liveWorkoutBuilder else { return }
        
        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distanceInMeters)
        let distanceSample = HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            quantity: distanceQuantity,
            start: self.startDate ?? Date() ,
            end: self.endDate ?? Date()
        )
        
        builder.add([distanceSample]) { (success, error) in
            if success {
                print("Distance updated successfully.")
            } else if let error = error {
                print("Error updating distance: \(error)")
            }
        }
    }
    
    
    // 이 함수 작동안함 에러도 없고 작동도 안하고  왜  try await builder.addSamples([distanceSample]) 들어가면 답이없음.
    // 위의원인은 finishworkout 전에 실행되야함.
    func updateWorkoutDistance(startDate : Date, endDate: Date, _ distanceInMeters: Double ,  completion: @escaping (Bool, Error?) -> Void ) {
        guard let builder = self.liveWorkoutBuilder else {
            print("workoutBuilder is nil")
            return }
        print("updateWorkoutDistance is proceed")
        let device = HKDevice.local()
        
        
        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distanceInMeters)
        let distanceSample = HKQuantitySample(
            type: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            quantity: distanceQuantity,
            start: startDate ,
            end: endDate,
            device :device,
            metadata: self.metadataForWorkout)
        
        print("distanceSample \(distanceSample)")
        builder.add([distanceSample]) { (success, error) in
            if success  {
                print("Distance updated successfully.")
            }else if let error = error {
                print("Error updating distance: \(error)")
            }
            else  {
                print("Error updating distance: unknown")
                
            }
            completion(success, error)
            
        }
    }
    func printWorkoutActivityType(workout: HKWorkout) {
        let activityType = workout.workoutActivityType
        print("Activity Type: \(activityType.rawValue)")
        
        if let totalDistance = workout.metadata?["TotalDistance"] as? Double  {
            let totalDistanceInt = Int(totalDistance)
            print("Total Distance: \(totalDistanceInt) m ")
        }
        switch activityType {
        case .sailing:
            print("This workout is sailing.")
        case .cycling:
            print("This workout is indoor cycling.")
        case .running:
            print("This workout is running.")
            // 추가적인 운동 유형에 대한 경우도 여기 추가
        default:
            print("Other activity type.")
        }
    }
    
 
    func startTimer() {
        print("startTimer started")
        Publishers.CombineLatest(LocationManager.shared.locationPublisher, LocationManager.shared.headingPublisher)
            .filter { [weak self] newLocation, newHeading in
                guard self != nil else {
                    print("weak self is nil")
                    return false
                }
                
                // 위치 정확도가 50 미터 이하일 때만 처리
                return newLocation.horizontalAccuracy < 50 && newLocation.verticalAccuracy < 50
            }
            .sink { [weak self] newLocation, newHeading in
                guard let self = self else {
                    print("Weak self is nil")
                    return
                }
                
                Task{
                    do {
                        let distance = newLocation.distance(from: self.previousLocation ?? newLocation)
                        print("insterting RouteData \(newLocation) distance: \(distance)")
                        
                        if self.previousLocation == nil || distance > self.locationChangeThreshold || abs(self.previousLocation?.course ?? 0 - newLocation.course) > self.headingChangeThreshold {
                            // insertRouteData 호출을 조건에 맞게 처리
                            try await self.insertRouteData([newLocation])
                        }
                        //  현재의  location값을 과거 location 값으로 정함
                        self.previousLocation = newLocation
                        self.totalDistance += distance
                        
                        print("totalDistance: \(String(describing: self.totalDistance) ) ")
                        
                    } catch {
                        print("insertRouteData error: \(error)")
                    }
                }
            }
            .store(in: &cancellables)
        
        
        windDetector.windPublisher
            .sink{  [weak self] windData in
                guard let self = self else {
                    print("weak self is nil")
                    return }
                let metadataForRouteDataPoint = metadataForRouteDataPoint(
                    id: UUID(),
                    timeStamp: windData.timestamp ?? Date(),
                    boatHeading: self.locationManager.heading?.trueHeading,
                    windSpeed: windData.speed,
                    windDirection: windData.direction,
                    windAdjustedDirection: windData.adjustedDirection
                )
                
                self.metadataForRouteDataPointArray.append(metadataForRouteDataPoint)
                print("metadataForRouteDataPointArray appended...")
            }.store(in: &cancellables   )
        
    }
    
    
    
    func insertRouteData(_ locations: [CLLocation]) {
        let status = healthStore.authorizationStatus(for: .workoutType())
        if status != .sharingAuthorized {
            print("HealthKit authorization is failed. Cannot insert route data.\(status)")
            return
        }
        else {
            print("HealthKit authorization is successful. \(status)")
        }
        
        
        workoutRouteBuilder?.insertRouteData(locations) { success, error in
            if success {
                print("RoutData inserted successfully in the insertRouteData(locations)")
                
            } else {
                print("Error inserting route data: \(String(describing: error))")
            }
        }
        
    }
    
    
    func insertRouteData(_ locations: [CLLocation]) async throws {
        let status = healthStore.authorizationStatus(for: .workoutType())
        guard status == .sharingAuthorized else {
            throw HealthKitError.authorizationFailed
        }
        
        guard let workoutRouteBuilder = workoutRouteBuilder else {
            print("workoutRouteBuilder is nil. Cannot insert route data.")
            throw HealthKitError.selfNilError
        }
        // 비동기 작업으로 변환
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            routeDataQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: HealthKitError.selfNilError)
                    return
                }
                workoutRouteBuilder.insertRouteData(locations) { success, error in
                    
                    if let error = error {
                        print("Error inserting route data: \(error.localizedDescription)")
                        return  continuation.resume(throwing: HealthKitError.routeInsertionFailed(error.localizedDescription))
                    }
                    
                    guard success else {
                        print("insertRouteData failed")
                        
                        return  continuation.resume(throwing: HealthKitError.unknownError)
                        
                    }
                    
                    let speed = locations.last?.speed  ?? 0
                    
                    if speed > self.maxSpeed  {
                        self.maxSpeed = speed
                    }
                    print("maxSpeed in workoutManager -- maxSpeed: \(self.maxSpeed) speed: \(speed)")
                    print("RouteData inserted successfully in the self.workoutRouteBuilder?.insertRouteData(locations)")
                    continuation.resume()
                }
            }
        }
    }
    
    
    func finishRoute(workout: HKWorkout, metadataForRoute: [String: Any]?) async -> Result<HKWorkoutRoute, Error> {
        return await withCheckedContinuation { continuation in
            workoutRouteBuilder?.finishRoute(with: workout, metadata: metadataForRoute) { route, error in
                
                if let error = error {
                    print("finishRoute: error \(error.localizedDescription)")
                    return continuation.resume(returning: .failure(error))
                }
                
                guard let route = route else {
                    print("finishRoute: Unknown error occurred, route is nil")
                    let unknownError = NSError(domain: "FinishRouteError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Route is nil"])
                    return continuation.resume(returning: .failure(unknownError))
                }
                
                print("finishRoute: workoutRoute saved successfully route \(route)")
                continuation.resume(returning: .success(route))
            }
        }
    }
    
    
    
    func startToSaveHealthStore() {
        
        let healthService = HealthService.shared
        let workoutManager = WorkoutManager.shared
        
        self.startDate = Date()
        //      sailingDataCollector.startDate = startDate
        
        healthService.startHealthKit()
        
        if let startDate  = startDate{
            workoutManager.startWorkout(startDate: startDate)
            print("-------------------- started to save HealthStore --------------------")
        }
        
    }
    
    func endToSaveHealthData(){
        let healthService = HealthService.shared
        let workoutManager = WorkoutManager.shared
        //       [String: Any]이지만 데이타가 긴경우 JsonString으로 변환 [String: String]
        //        let jsonData = try? JSONEncoder().encode(sailingDataCollector.sailingDataPointsArray)
        //        let jsonString = String(data: jsonData!, encoding: .utf8) ?? "[]"
        //        let startDate = sailingDataCollector.startDate
        //        let metadata: [String: Any] = [
        //            "AppIdentifier" : "seastheDay" ,   // 삭제하면  에러가없음
        //            "sailingDataPointsArray": jsonString // JSON 문자열 형태로 메타데이터에 추가
        //        ]
        
        self.endDate = Date()
        metadataForWorkout = makeMetadataForWorkout(appIdentifier: "seastheDay")
        print("metadata in the endToSaveHealthData: \(metadataForWorkout)")
        
        
        if let startDate = startDate, let endDate = endDate {
            workoutManager.collectData(startDate: startDate, endDate: endDate, metadataForWorkout: metadataForWorkout)
            print("collectData works successfully  in the endToSaveHealthData")
        }  else {
            print("startDate or endDate is nil")
        }
        
    }
    
    // jsonString을 디코드하면서 그 안에 엘리멘츠 숫자 파악. 구조체 [T].self 의 숫자 파악
    
    func countElements<T: Decodable>(in jsonString: String, of type: T.Type) -> Int? {
        // Convert JSON string to Data
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            // Decode JSON data into an array of the specified type
            let elements = try JSONDecoder().decode([T].self, from: data)
            // Return the count of elements
            return elements.count
        } catch {
            print("Failed to decode JSON: \(error)")
            return nil
        }
    }
    
    func makeMetadataForRoute(routeIdentifier: String, metadataForRouteDataPointArray : [metadataForRouteDataPoint]? ) -> [String: Any] {
        var metadataForRoute: [String: Any] = [:]
        metadataForRoute["RouteIdentifier"] = routeIdentifier
        let data = try? JSONEncoder().encode(metadataForRouteDataPointArray)
        let jsonString = String(data: data!, encoding: .utf8) ?? ""
        metadataForRoute["RouteData"] = jsonString
        
        return metadataForRoute
    }
    
    func makeMetadataForWorkout(appIdentifier: String) -> [String: Any] {
        var metadataForWorkout: [String: Any] = [:]
        
        metadataForWorkout["AppIdentifier"] = appIdentifier
        metadataForWorkout["TotalDistance"] =  self.totalDistance
        
        metadataForWorkout["TotalDuration"] =  self.workout?.duration
        metadataForWorkout["TotalEneryBurned"] =  self.workout?.totalEnergyBurned
        metadataForWorkout["MaxSpeed"] = self.maxSpeed
        metadataForWorkout[HKMetadataKeyIndoorWorkout] = false
        metadataForWorkout[HKMetadataKeyActivityType] = HKWorkoutActivityType.sailing.rawValue
        metadataForWorkout[HKMetadataKeyWorkoutBrandName] = "Sailing"
        
        let uuidStr = workout?.uuid.uuidString ??  UUID().uuidString
        metadataForWorkout[HKMetadataKeySyncIdentifier] = "\(appIdentifier)_workout_\(uuidStr)"
        metadataForWorkout[HKMetadataKeySyncVersion] = 1
        
        return metadataForWorkout
    }
    
    func labelForQuantityType(_ quantityType: HKQuantityType) -> String {
        switch quantityType.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return "Heart Rate"
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return "Distance"
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return "Calories"
        default:
            return "Data"
        }
    }
    
    
    
    func fetchTotalEnergyBurned(for workout: HKWorkout, completion: @escaping (HKQuantity?) -> Void) {
        // Get the total energy burned directly from the HKWorkout object
        let totalEnergyBurned = workout.totalEnergyBurned
        
        // Return the total energy burned value
        completion(totalEnergyBurned)
    }
    
    
    func fetchActiveEnergyBurned(startDate: Date, endDate: Date, completion: @escaping (HKQuantity?) -> Void) {
        let healthStore = HKHealthStore()
        
        // Create the quantity type for active energy burned
        let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // Create a predicate to filter data between the start and end date
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        // Create the sort descriptor to get the most recent data
   //     let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
      
        let statisticsQuery = HKStatisticsQuery(quantityType: activeEnergyBurnedType, quantitySamplePredicate:  predicate , options: .cumulativeSum) { _, result, _ in
            guard let result = result, let totalActiveEnergyBurned = result.sumQuantity() else {
                print("No data available in the fetchActiveEnergyBurned")
                return
            }
            print("totalActiveEnergyBurned: \(totalActiveEnergyBurned.doubleValue(for:.kilocalorie()))")
            completion(totalActiveEnergyBurned)
        }
        healthStore.execute(statisticsQuery)
    }
}





