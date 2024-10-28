//
//  HealthService.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/28/24.
//


import HealthKit
import WorkoutKit

class HealthService : ObservableObject {
    let healthStore = HKHealthStore()
 
    func startHealthKit()
    {
      
        // Create the heart rate and heartbeat type identifiers.
        var sampleTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!,
                               HKSeriesType.heartbeat(),
                               HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
                               
                              ])
        
        if let stepCount  = HKObjectType.quantityType(forIdentifier: .stepCount) {
            
            sampleTypes.insert(stepCount)
        }
        if let walkingSpeed = HKObjectType.quantityType(forIdentifier: .walkingSpeed) {
            sampleTypes.insert(walkingSpeed)
        }
        
        if let walkingSpeedLength =  HKObjectType.quantityType(forIdentifier: .walkingStepLength) {
            sampleTypes.insert(walkingSpeedLength)
        }
        
        if let distanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            
            sampleTypes.insert(distanceWalkingRunning)
        }
        if let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)  {
            sampleTypes.insert(caloriesType)
        }
        let workoutType = HKObjectType.workoutType()
        sampleTypes.insert(workoutType)
        
        
        // 공유될수없음 toShare 따로  read 따로
        //            if let walkingHeartRateAverage =   HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage) {
        //                sampleTypes.insert(walkingHeartRateAverage)
        //            }
        // Request permission to read and write heart rate and heartbeat data.
        
        healthStore.requestAuthorization(toShare: sampleTypes, read: sampleTypes) { (success, error) in
            print("Request Authorization -- Success: ", success, " Error: ", error ?? "nil")
            // Handle authorization errors here.
            
            
        }
    }
    
   
}
