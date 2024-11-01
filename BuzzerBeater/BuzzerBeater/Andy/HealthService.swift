//
//  HealthService.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/28/24.
//

import HealthKit
import WorkoutKit
import SwiftUI

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
     
        
        let workoutRouteType = HKSeriesType.workoutRoute()
        sampleTypes.insert(workoutRouteType)
       
        // 모든 HKSampleType은 HKObjectType이나 모든  HKObjectType이 반듯이  HKSampleType인것은 아니다.
        
        healthStore.requestAuthorization(toShare: sampleTypes , read: sampleTypes) { (success, error) in
            print("Request Authorization -- Success: ", success, " Error: ", error ?? "nil")
            // Handle authorization errors here.
            
        }
    }
     
}
