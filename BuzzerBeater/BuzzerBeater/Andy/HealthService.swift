//
//  HealthService.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/28/24.
//


import HealthKit
import WorkoutKit

class HealthService : ObservableObject {
    static  let shared = HealthService()
    let healthStore = HKHealthStore()
    var workoutBuilder: HKWorkoutBuilder?
    
    func startHealthKit() {
        var sampleTypes = Set<HKSampleType>()
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            sampleTypes.insert(heartRate)
        }
        
        let heartbeatSeries = HKSeriesType.heartbeat()
        sampleTypes.insert(heartbeatSeries)
        
        if let heartRateVariability = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            sampleTypes.insert(heartRateVariability)
        }
        
        if let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            sampleTypes.insert(distanceWalkingRunning)
        }
        
        if let activeEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            sampleTypes.insert(activeEnergyBurned)
        }
        
        if let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)  {
            sampleTypes.insert(caloriesType)
        }
        let workoutType = HKObjectType.workoutType()
        sampleTypes.insert(workoutType)
        
        // 모든 HKSampleType은 HKObjectType이나 모든  HKObjectType이 반듯이  HKSampleType인것은 아니다.
        
        healthStore.requestAuthorization(toShare: sampleTypes , read: sampleTypes) { (success, error) in
            print("Request Authorization -- Success: ", success, " Error: ", error ?? "nil")
            // Handle authorization errors here.
            
        }
    }
  
       
       func startWorkout(startDate: Date) {
           // 운동을 시작하기 전에 HKWorkoutBuilder를 초기화
          
           let workoutConfiguration = HKWorkoutConfiguration()
           workoutConfiguration.activityType = .sailing
           workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: nil)
           
           // 운동 구성
           workoutBuilder?.beginCollection(withStart: startDate, completion: { (success, error) in
               if success {
                   
                   print("Started collecting workout data.")
               } else {
                   print("Error starting workout collection: \(error?.localizedDescription ?? "Unknown error")")
               }
           })
       }
       
    func collectData(startDate: Date, endDate: Date, totalEnergyBurned: Double, totalDistance: Double, metadata: [String: Any]?) {
        // 데이터 수집 예시
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: totalEnergyBurned)
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let energySample = HKQuantitySample(type: energyType, quantity: energyQuantity, start: startDate, end: endDate)
        
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: totalDistance)
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let distanceSample = HKQuantitySample(type: distanceType, quantity: distanceQuantity, start: startDate, end: endDate)
        
        // 수집된 데이터 추가
        workoutBuilder?.add( [energySample],completion: { (success, error) in
            if success {
                print("Energy data added.")
            } else {
                print("Error adding energy data: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
        
        workoutBuilder?.add([distanceSample]) { (success, error) in
            if success {
                print("Distance data added.")
            } else {
                print("Error adding distance data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        
        finishWorkout(endDate: endDate, metadata: metadata)
        
    }
    
    func finishWorkout(endDate: Date, metadata: [String: Any]?) {
        let endDate = Date()
        workoutBuilder?.endCollection(withEnd: endDate) {[weak self] success, error in
            if success {
                print("Workout ended at \(endDate)")
                
                // Workout session을 마무리하고 HealthKit에 저장
                self?.workoutBuilder?.finishWorkout { workout, error in
                    if let workout = workout {
                        if let metadata = metadata {
                            
                            self?.workoutBuilder?.addMetadata(metadata) {  success, error in
                                
                                if success {
                                    print("Workout saved successfully: \(workout)")
                                }
                                else {
                                    print("Error saving metadata \(String(describing: error?.localizedDescription))")
                                }
                            }
                        }
                    } else if let error = error {
                        print("Error saving workout: \(error.localizedDescription)")
                    }
                }
            } else if let error = error {
                print("Error ending workout: \(error.localizedDescription)")
            }
        }
    }
    
}
