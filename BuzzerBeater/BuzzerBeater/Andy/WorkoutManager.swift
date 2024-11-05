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


struct metadataForRouteDataPoint: Equatable, Identifiable, Codable{
    var id: UUID = UUID()
    var timeStamp: Date
    var boatHeading : Double?
    var windSpeed: Double  // m/s
    var windDirection: Double?  //deg
    var windCorrectionDetent : Double
    
}



class WorkoutManager:  ObservableObject
{
    
    
    
    static let shared = WorkoutManager()
    let locationManager = LocationManager.shared
    let windDetector = WindDetector.shared
    let healthService = HealthService.shared
    let healthStore = HealthService.shared.healthStore
    
    
    let timeIntervalForRoute = TimeInterval(3)
    let timeIntervalForWind = TimeInterval(60*1)
    
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
    
    var timerForLocation: Timer?
    var timerForWind: Timer?
    var metadataForWorkout: [String: Any] = [:] // AppIdentifier, 날짜,
    var metadataForRoute: [String: Any] = [:]   // RouteIdentifer, timeStamp, WindDirection, WindSpeed
    var metadataForRouteDataPointArray : [metadataForRouteDataPoint] = []
    let routeDataQueue = DispatchQueue(label: "com.lavender.buzzbeater.routeDataQueue")
    // endTime은 3시간 이내로 제한 즉 한세션의 최대 크기를 제한하도록 함. 나중에 사용예정
    var startDate: Date?
    var endDate : Date?
    
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
        
        liveWorkoutBuilder.beginCollection(withStart: startDate, completion: { (success, error) in
            if success {
                print("Started collecting live workout dat from  ")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.startTimer()
                }
            } else {
                print("Error starting live workout collection: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
        
        
    }
    
    func collectData(startDate: Date, endDate: Date,  metadataForWorkout: [String: Any]?) {
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
        
        if let metadataForWorkout = metadataForWorkout {
            print("metadata in the collectData\(metadataForWorkout)")
            
            liveWorkoutBuilder.addMetadata(metadataForWorkout) { (success, error) in
                guard success else {
                    print("==========Error adding metadata:\(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                //    self.finishWorkout(endDate: endDate, metadataForWorkout: metadataForWorkout)
                Task {
                    await self.finishWorkoutAsync(endDate: endDate, metadataForWorkout: self.metadataForWorkout)
                }
                
            }
        }
        else{
            print("metadataForWorkout is nil or invalid")
            //  self.finishWorkout(endDate: endDate, metadataForWorkout: metadataForWorkout)
            Task {
                await self.finishWorkoutAsync(endDate: endDate, metadataForWorkout: self.metadataForWorkout)
            }
        }
        
        
    }
    
    
    func finishWorkout(endDate: Date, metadataForWorkout: [String: Any]?)   {
        
        if !isWorkoutActive {
            print("Workout is not active")
            return
        }
        isWorkoutActive = false
        // Use the parameter `endDate`
        
        timerForLocation?.invalidate() // 타이머 중지
        timerForWind?.invalidate()
        
        guard let liveWorkoutBuilder = self.liveWorkoutBuilder,
              // apple watch에서 liveWorkoutBuilder 만 있으면 충분하고 , workotuBuilder는 사용하지 않고 있음.
              //        let workoutBuilder = self.workoutBuilder,
                let workoutSession = self.workoutSession else {
            print("liveWorkoutBuilder, workoutBuilder, workoutSession is nil ")
            return
        }
        
        // workoutBuilder 대신에  liveWorkoutBuilder를 사용함
        // Apple  공식문서에  session.end()를 build.endCollection보다 먼저 실행함
        //https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/running_workout_sessions
        // 종료 순서가 중요함
        // 1.workoutSession을 가장 먼저 종료
        // 2.liveWorkoutBuilder?.endCollection 을 함
        // 3.liveWorkoutBuilder?.finishWorkout
        // 4.workoutRouteBuilder.finishRoute
        // Apple  공식문서에  session.end()를 build.endCollection보다 먼저 실행함
        //https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/running_workout_sessions
        
        print("workout session ended./(workoutSession) /(workoutSession.state.rawValue)")
        
        workoutSession.end()
        
        liveWorkoutBuilder.endCollection(withEnd: endDate) { [weak self] success, error in
            guard let self = self else { return } // Ensure `self` is valid
            guard success else {
                print("endCollection Error:\(error?.localizedDescription ?? "Unknown error")")
                return
            }
            print("Workout endCollection at \(endDate)")
            
            // Finish the workout and save it to HealthKit
            
            liveWorkoutBuilder.finishWorkout { workout, error in
                guard  let workout = workout else {
                    print("finishWorkout:\(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.printWorkoutActivityType(workout: workout)
                
                self.metadataForRoute = self.makeMetadataForRoute(routeIdentifier: "seastheDayroute", metadataForRouteDataPointArray: self.metadataForRouteDataPointArray)
                print("metadataForRoute \(self.metadataForRoute)")
                
                Task{
                    let result =   await self.finishRoute(workout: workout, metadataForRoute: self.metadataForRoute)
                    switch result {
                    case .success(let route):
                        print("Successfully finished route: \(route.uuid) count: \(route.count) ")
                        
                    case .failure(let error):
                        print("Failed to finish route with error: \(error.localizedDescription)")
                    }
                }
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
        isWorkoutActive = false
        
        // 타이머 중지
        timerForLocation?.invalidate()
        timerForWind?.invalidate()
        
        guard let liveWorkoutBuilder = self.liveWorkoutBuilder,
              let workoutSession = self.workoutSession else {
            print("liveWorkoutBuilder or workoutSession is nil")
            return
        }
        // workoutSession이 먼저 종료되어야 한다고 공식문서에 되있음.
        print("Ending workout session: \(workoutSession) with state: \(workoutSession.state.rawValue)")
        
        workoutSession.end()
        
        do {
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
                        print("Preparing to finish route with workout: \(workout) and metadata: \(String(describing: self.metadataForRoute))")
                        continuation.resume(returning: workout)  // Resume continuation after workout is finalized
                    } else {
                        print("finishWorkout Error: No workout returned from finishWorkout")
                        continuation.resume(throwing: HealthKitError.unknownError)
                    }
                }
            }
            
            Task {
                self.printWorkoutActivityType(workout: workout)
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
    
    
    func printWorkoutActivityType(workout: HKWorkout) {
        let activityType = workout.workoutActivityType
        print("Activity Type: \(activityType.rawValue)")
        
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
                if location.horizontalAccuracy < 30 && location.horizontalAccuracy > 0 {
                    Task{
                        do {
                            print("insterting RouteData \(location) ")
                            try await self.insertRouteData([location])
                            
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
        
        startDate = Date()
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
        
        endDate = Date()
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
    //
    //        func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
    //
    //        }
    //
    //        func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: any Error) {
    //
    //        }
    //
    //        func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    //
    //        }
    //        func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    //            for type in collectedTypes {
    //                guard let quantityType = type as? HKQuantityType else {
    //                    return
    //                }
    //
    //                // Calculate statistics for the type.
    //                let statistics = workoutBuilder.statistics(for: quantityType)
    //                let label = labelForQuantityType(quantityType)
    //
    //                DispatchQueue.main.async() {
    //                    if let recentQuantity = statistics?.mostRecentQuantity() {
    //                        // Convert the quantity to a user-friendly string with units
    //                        let quantityString = recentQuantity.doubleValue(for: HKUnit.meter()) // 예를 들어, 미터 단위로 변환
    //                        let formattedQuantity = String(format: "%.2f", quantityString) + " " + label
    //
    //                        // Assume `quantityLabel` is a UILabel for displaying this data
    //                        print("Latest \(label): \(formattedQuantity)")
    //                    } else {
    //                        print( "No data for \(label)")
    //                    }
    //                }
    //            }
    //        }
    //
}


