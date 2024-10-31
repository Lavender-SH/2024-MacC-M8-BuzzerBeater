//
//  WorkoutManager.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/30/24.
//

import HealthKit
import CoreLocation

struct metadataForRouteDataPoint: Equatable, Identifiable, Codable{
    var id: UUID = UUID()
    var timeStamp: Date
  
    var boatHeading : Double
    
    var windSpeed: Double  // m/s
    var windDirection: Double?  //deg
    var windCorrectionDetent : Double
       
}


class WorkoutManager: NSObject, CLLocationManagerDelegate {
    static let shared = WorkoutManager()
    let locationManager = LocationManager.shared
    let windDetector = WindDetector.shared
    let healthService = HealthService.shared
    let healthStore = HealthService.shared.healthStore
    
    
    let timeIntervalForRoute = TimeInterval(10)
    let timeIntervalForWind = TimeInterval(60*10)
    
    var workout: HKWorkout?
    var workoutBuilder: HKWorkoutBuilder?
    var workoutSession: HKWorkoutSession?
    var workoutRouteBuilder: HKWorkoutRouteBuilder?
    var isWorkoutActive: Bool = false
    
    var lastHeading: CLHeading?
    
    var timerForLocation: Timer?
    var timerForWind: Timer?
    var metadataForworkout: [String: Any] = [:] // AppIdentifier, 날짜,
    var metadataForRoute: [String: Any] = [:]   // RouteIdentifer, timeStamp, WindDirection, WindSpeed
    
    
    // endTime은 3시간 이내로 제한 즉 한세션의 최대 크기를 제한하도록 함.
    var startDate: Date?
    var endDate : Date?
    
    var metadataForRouteDataPointArray : [metadataForRouteDataPoint] = []
    
    
    // 기존의  locationManager사용
    
    override init() {
        super.init()
        healthService.startHealthKit()



    }

    
    func startWorkout(startDate: Date) {
        // 운동을 시작하기 전에 HKWorkoutBuilder를 초기화
        if isWorkoutActive  { return }
        isWorkoutActive = true
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .sailing
        workoutConfiguration.locationType = .outdoor
        
    
        workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())
        guard let workoutBuilder = workoutBuilder else { return }
        // 운동 구성
     
        
        workoutBuilder.beginCollection(withStart: startDate, completion: { (success, error) in
            if success {

                print("Started collecting workout data.")
            } else {
                print("Error starting workout collection: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
        
        
//        HKWorkoutRouteBuilder의 주요 메서드
//        insertRouteData: CLLocation 배열을 전달해 경로 데이터를 추가
//        finishRoute: 모든 경로 데이터를 추가한 후, 경로 데이터를 HealthKit에 저장

        workoutRouteBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: .local())
        
        startTimer()
     
        

    }
    
    func collectData(startDate: Date, endDate: Date, totalEnergyBurned: Double, totalDistance: Double, metadatForWorkout: [String: Any]?) {
        // 데이터 수집 예시
        guard let workoutBuilder = workoutBuilder else { return }
        
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalEnergyBurned)
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: startDate, end: endDate)
        
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: totalDistance)
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: startDate, end: endDate)
        
        // 수집된 데이터 추가
        workoutBuilder.add( [energySample],completion: { (success, error) in
            if success {
                print("Energy data added.")
            } else {
                print("Error adding energy data: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
        
        workoutBuilder.add([distanceSample]) { (success, error) in
            if success {
                print("Distance data added.")
            } else {
                print("Error adding distance data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        
        
        if let metadatForWorkout = metadatForWorkout {
            print("metadata in the collectData\(metadatForWorkout)")
        
            workoutBuilder.addMetadata(metadatForWorkout) { (success, error) in
                if success {
                    print("===================workoutBuilder addMetadata successfully ===================")
                    
                    
                    
                    self.finishWorkout(endDate: endDate, metadatForWorkout: metadatForWorkout)
                  
                } else if let error = error {
                    print("==========Error adding metadata:\(error.localizedDescription)")
                    self.finishWorkout(endDate: endDate, metadatForWorkout: metadatForWorkout)
                } else {
                    print("==========Error adding metadata: unknown error========================")
                    self.finishWorkout(endDate: endDate, metadatForWorkout: metadatForWorkout)
                    
                }
            }
        } else {
            print("metadatForWorkout is nil or invalid")
            self.finishWorkout(endDate: endDate, metadatForWorkout: metadatForWorkout)
        }
        
        
    }
    
    
    
    func finishWorkout(endDate: Date, metadatForWorkout: [String: Any]?) {
        
        if !isWorkoutActive {
            return
        }
        isWorkoutActive = false
        
        
        // Use the parameter `endDate`
        timerForLocation?.invalidate() // 타이머 중지
        timerForWind?.invalidate()
        workoutBuilder?.endCollection(withEnd: endDate) { [weak self] success, error in
            guard let self = self else { return } // Ensure `self` is valid
            
            if success {
                print("Workout ended at \(endDate)")
                
                // Finish the workout and save it to HealthKit
                workoutBuilder?.finishWorkout { workout, error in
                    if let workout = workout {
                        self.printWorkoutActivityType(workout: workout)
                        // ====================== workout과  workoutRoute 연결 ========================
                        //finishRoute: 모든 경로 데이터를 추가한 후, 경로 데이터를 HealthKit에 저장하기 위해 호출하는 메서드
                        self.finishRoute(workout: workout, metadataForRoute: self.metadataForRoute)
                        print("========== finishWorkout successfully workout:==========  \(String(describing: workout.metadata))")
                    } else if let error = error {
                        print("Error finishing workout: \(error.localizedDescription)")
                    }
                }
            } else if let error = error {
                print("Error ending workout: \(error.localizedDescription)")
            }
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
        timerForLocation = Timer.scheduledTimer(withTimeInterval: timeIntervalForRoute, repeats: true) { [weak self] _ in
            guard let self = self else { return }
          
            if let location = self.locationManager.lastLocation  {
                print("location inserRouteData: \(location)")
               // path정보 추가 //  LocationManager의 location, direction, heading 정보를 저장
                //finishRoute: 모든 경로 데이터를 추가한 후, 경로 데이터를 HealthKit에 저장하기 위해 호출하는 메서드입니다
                self.insertRouteData(location)
                print("insterting RouteData")
                //
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
                                                                              boatHeading: self.locationManager.heading?.trueHeading ?? 0,
                                                                              windSpeed: self.windDetector.speed ?? 0,
                                                                              windDirection: self.windDetector.direction,
                                                                              windCorrectionDetent: self.windDetector.windCorrectionDetent
                    )
                    
                    self.metadataForRouteDataPointArray.append(metadataForRouteDataPoint)
                    print("metadataForRouteDataPointArray appeneded...")
                }
            }
        }
        
    }
    
    

    func insertRouteData(_ location: CLLocation) {
        let status = healthStore.authorizationStatus(for: .workoutType())
        if status != .sharingAuthorized {
                print("HealthKit authorization is failed. Cannot insert route data.\(status)")
                return
            }
        else {
            print("HealthKit authorization is successful. \(status)")
        }
        
        workoutRouteBuilder?.insertRouteData([location]) { success, error in
            if success {
                print("Route data inserted successfully.")
                
            } else {
                print("Error inserting route data: \(String(describing: error))")
            }
        }
    }
    
    func finishRoute(workout : HKWorkout, metadataForRoute: [String: Any]?) {
        
        workoutRouteBuilder?.finishRoute(with: workout, metadata: metadataForRoute)  { route, error in
            
            if (route != nil && error == nil) {
                print("===================finishRoute: workoutRoute saved successfully====================")
            }
            else {
                
                print("===================finishRoute: workoutRoute saving failed: \(String(describing: error))")
                
            }
        }
        
        
    }
    
    
    
    func startToSaveHealthStore() {
       
        let healthService = HealthService.shared
        let healthStore = healthService.healthStore
        let workoutManager = WorkoutManager.shared
        startDate = Date()
//        sailingDataCollector.startDate = startDate
        
        healthService.startHealthKit()
        if let startDate  = startDate{
            workoutManager.startWorkout(startDate: startDate)
            print("-------------------- started to save HealthStore --------------------")
        }
   
    }
    
    func endToSaveHealthData(){
        let healthService = HealthService.shared
        let healthStore = healthService.healthStore
        let workoutManager = WorkoutManager.shared
        
//        let jsonData = try? JSONEncoder().encode(sailingDataCollector.sailingDataPointsArray)
//        let jsonString = String(data: jsonData!, encoding: .utf8) ?? "[]"
          endDate = Date()
//        let startDate = sailingDataCollector.startDate
        
        let metadata: [String: Any] = [
            "AppIdentifier" : "seastheDay" ,   // 삭제하면  에러가없음
  //          "sailingDataPointsArray": jsonString // JSON 문자열 형태로 메타데이터에 추가
        ]
        print("metadata in the endToSaveHealthData: \(metadata)")
        
        if let sailingDataPointsArray = metadata["sailingDataPointsArray"] as? String {
            print("metadata Count :\(countElements(in: sailingDataPointsArray) ?? 0)")
            print("metadata sailingDataPointsArray: \(sailingDataPointsArray)")
        } else {
            print("sailingDataPointsArray is not a String")
        }
    
       if let startDate = startDate, let endDate = endDate {
           workoutManager.collectData(startDate: startDate, endDate: endDate, totalEnergyBurned: 888, totalDistance: 999, metadatForWorkout: metadata)
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
}


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
