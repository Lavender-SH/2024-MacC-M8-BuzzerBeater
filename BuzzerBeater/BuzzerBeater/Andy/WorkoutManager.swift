
//WorkoutManagerIOS.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/30/24.
//
import CoreLocation
import HealthKit
import Foundation
import SwiftUI
import WorkoutKit

struct metadataForRouteDataPoint: Equatable, Identifiable, Codable{
    var id: UUID = UUID()
    var timeStamp: Date
    
    var boatHeading : Double?
    
    var windSpeed: Double  // m/s
    var windDirection: Double?  //deg
    var windCorrectionDetent : Double
    
}


class WorkoutManager: ObservableObject
{
    static let shared = WorkoutManager()
    let locationManager = LocationManager.shared
    let windDetector = WindDetector.shared
    let healthService = HealthService.shared
    let healthStore = HealthService.shared.healthStore
    
    
    let timeIntervalForRoute = TimeInterval(3)
    let timeIntervalForWind = TimeInterval(60*30)
    
    var workout: HKWorkout?
    var workoutBuilder: HKWorkoutBuilder?
    var workoutSession: HKWorkoutSession?
    var workoutRouteBuilder: HKWorkoutRouteBuilder?
    
    // for later use
    var appIdentifier: String?
    var routeIdentifier: String?
    
    var isWorkoutActive: Bool = false
    var lastHeading: CLHeading?
    
    var timerForLocation: Timer?
    var timerForWind: Timer?
    var metadataForWorkout: [String: Any] = [:] // AppIdentifier, 날짜,
    var metadataForRoute: [String: Any] = [:]   // RouteIdentifer, timeStamp, WindDirection, WindSpeed
    var metadataForRouteDataPointArray : [metadataForRouteDataPoint] = []
    let routeDataQueue = DispatchQueue(label: "com.lavender.buzzbeater.routeDataQueue")
    
    // endTime은 3시간 이내로 제한 즉 한세션의 최대 크기를 제한하도록 함. 나중에 사용예정
    // 기존의  locationManager사용
    
    var startDate: Date?
    var endDate : Date?
    var previousLocation: CLLocation?
    var totalDistance: Double = 0
    var totalEnergyBurned : Double = 0
    var activeEnergyBurned : Double = 0
    
    func startWorkout(startDate: Date) {
        // 운동을 시작하기 전에 HKWorkoutBuilder를 초기화
        if isWorkoutActive  { return }
        isWorkoutActive = true
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .sailing
        workoutConfiguration.locationType = .outdoor
        
      
        workoutBuilder =  HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
        
        guard let workoutBuilder = workoutBuilder else {
            print("workoutBuilder is nil ")
            return
        }
        workoutRouteBuilder = HKWorkoutRouteBuilder(healthStore: self.healthStore, device: .local())
        
        //  IOS에서 workoutBuilder를 정확하게 사용하기 위함.. 없어도 동작함.
        
        let workoutActivity = HKWorkoutActivity(workoutConfiguration: workoutConfiguration, start: startDate, end:nil, metadata: nil)
       
        //
        workoutBuilder.beginCollection(withStart: startDate, completion: { (success, error) in
            if success {
                print("Started collecting workout data from workoutBuilder \(String(describing: self.workoutBuilder))")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.startTimer()
                    //for test to writable.
                    self.updateActiveEnergyBurned(startDate: startDate, endDate: Date(), 1.0)
                    
                }
                workoutBuilder.addWorkoutActivity(workoutActivity){ (success, error) in
                    guard error == nil else {
                        print("error is not nil. error: \(String(describing: error))")
                        return }
                    guard success == true else {
                        print("fail to addWorkoutActivity.")
                        return
                    }
                    
                    print("addWorkoutActivity is success.")
                }
            } else {
                print("Error starting workout collection: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
        
        
    }
    
    func collectData(startDate: Date, endDate: Date,  metadataForWorkout: [String: Any]?) {
        // 데이터 수집 예시
        
        guard let workoutBuilder = workoutBuilder else {
            print("workoutBuilder is nil")
            return
        }
        // IOS에서 우선 startDate과  endDate사이에 activeEnergyBurned SampleQuantity가 있으면 그것들의 합계를 다시 나의 workout을 통해서
        // 저장한다.
        // SampleQuantity가 저장되어있어야  StatisticsQuery로 합계를 가져올수가 았다.
        // 어째든 workoutBuilder를 통해서 workout을 생성하고 HealthKit에 샘플을 저장하고  HealthKit이 workout 객체에 값을 넣는지 관찰한다.
        //
        
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
        
        // 내가 저장하고 가장 큰값을 가져오는데 사실은 직접계산해서 BuzzBeater가 데이터 소스로 입력해줘야함.
        fetchActiveEnergyBurned(startDate: startDate, endDate: endDate){ activeEnergyBurnedQuantity in
            
            if  let activeEnergyBurnedQuantity = activeEnergyBurnedQuantity{
                let activeEnergyBurned = activeEnergyBurnedQuantity.doubleValue(for: .kilocalorie())
                print("activeEnergyBurned in the collectData\(activeEnergyBurnedQuantity)")
                self.updateActiveEnergyBurned(startDate: startDate, endDate: endDate, activeEnergyBurned)
            } else {
                print("activeEnergyBurned in the collectData is nil")
                self.updateActiveEnergyBurned(startDate: startDate, endDate: endDate, 0)
            }
            
        }
        if let metadataForWorkout = metadataForWorkout {
            print("metadata in the collectData\(metadataForWorkout)")
            workoutBuilder.addMetadata(metadataForWorkout) { (success, error) in
                guard success else {
                    print("==========Error adding metadata:\(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                Task {
                    await self.finishWorkoutAsync(endDate: endDate, metadataForWorkout: self.metadataForWorkout)
                }
            }
        }
        else{
            print("metadataForWorkout is nil or invalid")
            Task {
                await self.finishWorkoutAsync(endDate: endDate, metadataForWorkout: self.metadataForWorkout)
            }
        }
    }
    
    // async 버전으로 만들고  await 을사용해서 모든 비동기호출을 마치고 종료할수있도록 함
    // try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>)
    // let workout = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKWorkout, Error>)
    
    func finishWorkoutAsync(endDate: Date, metadataForWorkout: [String: Any]?) async {
        if !isWorkoutActive {
            print("Workout is not active \(isWorkoutActive)")
            return
        }
        DispatchQueue.main.async {
            self.isWorkoutActive = false
            self.timerForLocation?.invalidate() // 타이머 중지
            self.timerForWind?.invalidate()
          
        }
        
        
        guard let workoutBuilder = self.workoutBuilder else {
            print("WorkoutBuilder is nil in finishWorkoutAsync ")
            return
        }
        print("workoutBuilder is not nil in finishWorkoutAsync \(workoutBuilder.allStatistics)")
        
        // workoutSession이 먼저 종료되어야 한다고 공식문서에 되어있으나 IOS에서 사용하지 않으
        // HKQauantitySample에 추가해봤으나 작동 안함.
        //  self.updateWorkoutDistance(self.totalDistance )
        
        do {
            try await self.updateActivityAsync(workoutBuilder: workoutBuilder, endDate: endDate)
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                workoutBuilder.endCollection(withEnd: endDate) { success, error in
                    if let error = error {
                        print("endCollection Error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else {
                        print("Workout endCollection at \(endDate)")
                        continuation.resume()
                    }
                }
            }
          
            let workout = try await withCheckedThrowingContinuation {(continuation: CheckedContinuation<HKWorkout, Error>) in
                workoutBuilder.finishWorkout { workout, error in
                    if let error = error {
                        print("finishWorkout Error: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    } else if let workout = workout {
                        
                        self.workout = workout
                        if let totalDistance = workout.metadata?["TotalDistance"] as? Double {
                            let totalDistanceInt = Int(totalDistance)
                            
                            DispatchQueue.main.async {
                                self.totalDistance = totalDistance
                            }
                            
                            print("Workout finished with total distance: \(totalDistanceInt) meters")
                        } else {
                            print("No distance data available.")
                        }

                       print("Preparing to finish route with workout: \(workout) and metadata: \(String(describing: self.metadataForRoute))")
                        
                        // Resume continuation after workout is finalized
                        if let totalDistance = workout.metadata?["TotalDistance"] as? Double {
                            let totalDistanceInt = Int(totalDistance)
                            print("Workout finished with total distance: \(totalDistanceInt) meters")
                        } else {
                            print("No distance data available.")
                        }
                        print("workoutUUID in: \(workout.uuid)")
                        
                        continuation.resume(returning: workout)
                    } else {
                        continuation.resume(throwing:  HealthKitError.unknownError)
                    }
                }
            }
            
            // Handle route completion separately after finishing the workout
            self.printWorkoutActivityType(workout: workout)
            self.metadataForRoute = self.makeMetadataForRoute(
                routeIdentifier: "seastheDayroute",
                metadataForRouteDataPointArray: self.metadataForRouteDataPointArray
            )
            
            
            Task {
                
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
    
    
    func updateActivityAsync(workoutBuilder: HKWorkoutBuilder? , endDate: Date?) async throws {
        // 첫 번째 비동기 작업: updateActivity
        guard let workoutBuilder = workoutBuilder else {
            return
        }
        guard let endDate = endDate else {
            return
        }
        if let lastActivity = workoutBuilder.workoutActivities.last  {
            print("lastActivity: \(lastActivity)  \(lastActivity.uuid) ")
            let workoutActivityUUID = lastActivity.uuid
            let endDate = endDate
            if lastActivity.endDate == nil {
                
                do {
                    try await updateActivity(uuid: workoutActivityUUID, end: endDate)
                    print("Update successful for activity UUID: \(workoutActivityUUID) lastActivity statistics: \(lastActivity.allStatistics)")
                } catch {
                    print("Error in updateActivity: \(error.localizedDescription)")
                }
                
            } else {
                print("Activity already ended. we can't change it Error!!!")
            }
            
            
        }
        else {
            print("No workout activities available.")
        }
    }
    func updateActivity(uuid: UUID, end: Date) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            guard let workoutBuilder = workoutBuilder else {
                return continuation.resume(throwing: NSError(domain: "updateActivity", code: 0, userInfo: nil))
            }
            workoutBuilder.updateActivity(uuid: uuid,end: end) { success, error in
                if success {
                    print("updateActivity success")
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "updateActivity", code: 0, userInfo: nil))
                }
            }
        }
    }
    
    // 이 함수 작동안함 에러도 없고 작동도 안하고  왜  try await builder.addSamples([distanceSample]) 들어가면 답이없음.
    // 위의원인은 finishworkout 전에 실행되야함.
    func updateWorkoutDistance(startDate : Date, endDate: Date, _ distanceInMeters: Double ,  completion: @escaping (Bool, Error?) -> Void ) {
        guard let builder = self.workoutBuilder else {
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
//builder.addSamples
//        Task {
//            do {
//                try await builder.addSamples([distanceSample])
//                print("Distance updated successfully.")
//                completion(true, nil)
//            } catch {
//                print("Error updating distance: \(error.localizedDescription)")
//                completion(false, error)
//            }
//        }
        
//healthStore.save
//        Task {
//            do {
//               try await healthStore.save(distanceSample)
//                print("Distance updated successfully.")
//                completion(true, nil)
//            } catch {
//                print("Error updating distance: \(error.localizedDescription)")
//                completion(false, error)
//            }
//        }
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
        timerForLocation = Timer.scheduledTimer(withTimeInterval: timeIntervalForRoute, repeats: true) { [weak self] _ in
            print("timerForLocation started ")
            guard let self = self else {
                print("weak self is nil")
                return }
            if let location = self.locationManager.lastLocation  {
                print("location.horizontalAccuracy: \(location.horizontalAccuracy) location.verticalAccuracy: \(location.verticalAccuracy) ")
                if location.horizontalAccuracy < 50 {
                    Task{
                        do {
// distance(from:)
// Returns the distance (measured in meters) from the current object’s location to the specified location.

                            let distance = location.distance(from: self.previousLocation ?? location)
                            print("insterting RouteData \(location) distance: \(distance)")
                            try await self.insertRouteData([location])
                            //  현재의  location값을 과거 location 값으로 정함
                            self.previousLocation = location
                            self.totalDistance += distance
                            
                            print("totalDistance: \(self.totalDistance ) ")
                            
                        } catch {
                            print("insertRouteData error: \(error)")
                        }
                    }
                } else {
                    print("location accuracy is too low")
                }
            } else {
                print("location is nil")
            }
            
        }
        
        timerForWind = Timer.scheduledTimer(withTimeInterval: timeIntervalForRoute ,  repeats: true) { [weak self] _ in
            // locationManager에값이 있지만 직접 다시 불러오는걸로 테스트를 해보기로함.
            // 이건 태스트목적뿐이고 실제는 그럴 필요가 전혀 없음.
            guard let self = self else { return }
            self.locationManager.locationManager.requestLocation()
            if let location = self.locationManager.locationManager.location {
                // wind 정보 추가  WindDetector에서 direction, speed 정보를 가져와서 metadata 에 저장
                Task{
                    await self.windDetector.fetchCurrentWind(for: location)
                    let metadataForRouteDataPoint = metadataForRouteDataPoint(id: UUID(),
                                                                              timeStamp: Date(),
                                                                              boatHeading: self.locationManager.heading?.trueHeading,
                                                                              windSpeed: self.windDetector.speed ?? 0,
                                                                              windDirection: self.windDetector.direction,
                                                                              windCorrectionDetent: self.windDetector.windCorrectionDetent
                    )
                    
                    self.metadataForRouteDataPointArray.append(metadataForRouteDataPoint)
                    print("metadataForRouteDataPointArray appended...")
                }
            }
        }
        
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
                print("Route data inserted successfully.")
                
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
        
        // 비동기 작업으로 변환
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            routeDataQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: HealthKitError.selfNilError)
                    return
                }
                
                self.workoutRouteBuilder?.insertRouteData(locations) { success, error in
                    if let error = error {
                        print("Error inserting route data: \(error.localizedDescription)")
                        return  continuation.resume(throwing: HealthKitError.routeInsertionFailed(error.localizedDescription))
                    }
                    guard success else {
                        return  continuation.resume(throwing: HealthKitError.unknownError)
                    }
                    print("Route data inserted successfully.")
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
        //        sailingDataCollector.startDate = startDate
        
        healthService.startHealthKit()
        if let startDate  = startDate{
            workoutManager.startWorkout(startDate: startDate)
            print("-------------------- started to save HealthStore --------------------")
        }
        
    }
    
    func endToSaveHealthData(){
        let workoutManager = WorkoutManager.shared
        
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
    func countElements(in jsonString: String) -> Int? {
        // Convert JSON string to Data
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        do {
            // Decode JSON data into an array of numbers
            let numbers = try JSONDecoder().decode([SailingDataPoint].self, from: data)
            // Return the count of elements
            return numbers.count
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
        metadataForWorkout[HKMetadataKeyIndoorWorkout] = false
        metadataForWorkout[HKMetadataKeyActivityType] = HKWorkoutActivityType.sailing.rawValue
        metadataForWorkout[HKMetadataKeyWorkoutBrandName] = "Sailing"
       
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
        if let totalEnergyBurned = workout.totalEnergyBurned {
            
            // Return the total energy burned value
            completion(totalEnergyBurned)
        } else {
            fetchActiveEnergyBurned(startDate: workout.startDate, endDate: workout.endDate) {
                activeEnergyBurned in
                if let activeEnergyBurned  = activeEnergyBurned{
                    
                    completion(activeEnergyBurned)
                    print("activeEnergyBurned fetched successfully \(activeEnergyBurned)")
                    
                } else {
                    completion(nil)
                    print("activeEnergyBurned is nil")
                }
            }
        }
    }
    func fetchActiveEnergyBurned(startDate: Date, endDate: Date, completion: @escaping (HKQuantity?) -> Void) {
        let healthStore = HKHealthStore()
        
        // Create the quantity type for active energy burned
        let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [.strictStartDate, .strictEndDate])
        
        // Get the source for this device (e.g., only include samples from the iPhone)
        // 현재는 devidePredicate sourcePredicate모두 Query결과가 Null 임
        // 일단 .or로 값을 보여주고 나중에 미세조정
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let sourcePredicate = HKQuery.predicateForObjects(from: [HKSource.`default`()])
        // Create the sort descriptor to get the most recent data
        let predicate1 = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, sourcePredicate])
        let predicate2 = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, devicePredicate])
        let orPredicate = NSCompoundPredicate(type:.or, subpredicates: [datePredicate, predicate2, predicate1])
        
        let statisticsQuery = HKStatisticsQuery(quantityType: activeEnergyBurnedType, quantitySamplePredicate: orPredicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let totalActiveEnergyBurned = result.sumQuantity() else {
                print("No data available in the statisticsQuery")
                completion(nil)
                return
            }
            let totalActiveEngeryBurned  = totalActiveEnergyBurned.doubleValue(for:.kilocalorie())
         print("totalActiveEnergyBurned: \(totalActiveEnergyBurned.doubleValue(for:.kilocalorie()))")
            completion(totalActiveEnergyBurned)
        }
        healthStore.execute(statisticsQuery)
        
        // 임시방편으로 IOS에서만 직접 activeEnergyBurned를 저장한다.
        
       
        
    }
    
    func updateActiveEnergyBurned(startDate : Date, endDate:Date , _ energyBurned: Double) {
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: energyBurned)
        let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        guard let  workoutBuilder =  workoutBuilder else {
            print("workoutBuilder is nil")
            return }
        let device = HKDevice.local()
        let energySample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                            quantity: energyQuantity,
                                            start: startDate,
                                            end: endDate,
                                            device: device,
                                            metadata: nil)

        workoutBuilder.add([energySample]) { success, error in
            if !success {
                print("Error adding energy burned sample: \(error?.localizedDescription ?? "unknown error")")
            }
            else {
                print("Successfully added energy burned sample")
            }
        }
    }

}
/*    HKSampleQuery 는 하나의 샘플만 가져옴 하나의 workout에 여러 Sample이 존재하고 이것에 대한 합계는 StatisticsQuery를 사용함
//    func fetchActiveEnergyBurned(startDate: Date, endDate: Date, completion: @escaping (HKQuantity?) -> Void) {
//        let healthStore = HKHealthStore()
//
//        // Create the quantity type for active energy burned
//        let activeEnergyBurnedType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
//
//        // Create a predicate to filter data between the start and end date
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
//
//        // Create the sort descriptor to get the most recent data
//        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
//
//        // Create the sample query to fetch the data
//        let query = HKSampleQuery(sampleType: activeEnergyBurnedType,
//                                  predicate: predicate,
//                                  limit: 1,
//                                  sortDescriptors: [sortDescriptor]) { (query, results, error) in
//            guard let results = results, let sample = results.first as? HKQuantitySample else {
//                completion(nil)
//                return
//            }
//
//            // Get the active energy burned value
//            let energyQuantity = sample.quantity
//
//            // Return the quantity
//            completion(energyQuantity)
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }


*/
/*
 
 1. **`HKWorkout` 생성 및 저장**:
 - 새로운 `HKWorkout` 객체를 생성하고, `healthStore.save(workout)`을 통해 HealthKit에 저장합니다.
 
 2. **`HKWorkoutRouteBuilder`를 사용하여 경로 데이터 삽입**:
 - `insertRouteData(_:)` 메서드를 호출하여 위치 데이터를 경로에 추가합니다.
 
 3. **경로 마무리 및 메타데이터 저장**:
 - `finishRoute(with:metadata:completion:)` 메서드를 호출하여 `HKWorkoutRoute`를 마무리하고 메타데이터를 추가합니다.
 
 4. **운동 마무리 및 메타데이터 저장**:
 - 운동이 완료되면, `healthStore.end(workout, with: metadata)`와 같은 방법으로 `HKWorkout`을 마무리하고 추가적인 메타데이터를 저장합니다.
 
 이러한 과정을 통해 `HKWorkout`과 `HKWorkoutRoute`가 각각의 메타데이터와 함께 연결되고 저장됩니다. 이 방식으로 운동과 경로에 대한 정보를 효과적으로 관리할 수 있습니다.
 
 
 
 
 */
