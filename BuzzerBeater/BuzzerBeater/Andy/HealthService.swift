//
//  HealthService.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/28/24.
//

import HealthKit
import SwiftUI

enum HealthKitError: Error {
    case authorizationFailed
    case unknownError
    case routeInsertionFailed(String) // 에러 메시지를 포함할 수 있음
    case selfNilError

    var localizedDescription: String {
        switch self {
        case .authorizationFailed:
            return "HealthKit authorization failed."
        case .unknownError:
            return "An unknown error occurred."
        case .routeInsertionFailed(let message):
            return "Route insertion failed: \(message)"
        case .selfNilError:
            return "Self is nil, cannot proceed."
        }
    }
}

class HealthService : ObservableObject {
    static let shared = HealthService()
    let healthStore = HKHealthStore()
    
  
    func startHealthKit() {
        var sampleTypes = Set<HKSampleType>()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("health data is not available")
            return
        }
        
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            sampleTypes.insert(heartRate)
        }
        
        if let distanceWalkingRunning = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            sampleTypes.insert(distanceWalkingRunning)
        }
        
        if let activeEnergyBurned = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            sampleTypes.insert(activeEnergyBurned)
        }
        
        let workoutType = HKWorkoutType.workoutType()
        sampleTypes.insert(workoutType)
        let workoutRouteType = HKSeriesType.workoutRoute()
        sampleTypes.insert(workoutRouteType)
        
        // 모든 HKSampleType은 HKObjectType이나 모든  HKObjectType이 반듯이  HKSampleType인것은 아니다.
        
        healthStore.requestAuthorization(toShare: sampleTypes , read: sampleTypes) { (success, error) in
            DispatchQueue.main.async {
                if success {
                    print("HealthKit Request Authorization -- Success")
                    // Handle post-authorization logic here, if needed.
                    self.checkAuthorizationStatus()
                } else {
                    print("HealthKit Request Authorization -- Failed: \(error?.localizedDescription ?? "Unknown error")")
                    // Handle authorization failure here, e.g., notify the user.
                    self.checkAuthorizationStatus()
                }
            }
        }
        
    }
    
    
    func checkAuthorizationStatus() {
        // HealthKit 데이터 유형 정의
        print("----------HealthKit Authorization Status---------")
        
        // Define the health data types to check authorization status for
        let healthTypes: [(HKObjectType, String)] = [
            (HKQuantityType.quantityType(forIdentifier: .heartRate)!, "Heart Rate"),
            (HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!, "Distance Walking/Running"),
            (HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!, "Active Energy Burned"),
            (HKObjectType.workoutType(), "Workout"),
            (HKSeriesType.workoutRoute(), "Workout Route")
        ]
        
        // Iterate through the health types and print their authorization status
        for (healthType, typeName) in healthTypes {
            let readStatus = healthStore.authorizationStatus(for: healthType)
            
            // For each health type, we need to create a specific HKSampleType to check the share permissions
            let writeStatus: HKAuthorizationStatus
            
            if let quantityType = healthType as? HKQuantityType {
                writeStatus = healthStore.authorizationStatus(for: quantityType)
            } else if let seriesType = healthType as? HKSeriesType {
                writeStatus = healthStore.authorizationStatus(for: seriesType)
            } else if let workoutType = healthType as? HKWorkoutType {
                writeStatus = healthStore.authorizationStatus(for: workoutType)
            }
            else {
                writeStatus = .notDetermined
            }
            
            let readMessage: String
            let writeMessage: String
            
            // Constructing messages for read and write statuses
            switch readStatus {
            case .sharingAuthorized:
                readMessage = "Authorized for reading"
            case .sharingDenied:
                readMessage = "Denied for reading"
            case .notDetermined:
                readMessage = "Not determined yet for reading"
            default:
                readMessage = "Not Authorized for reading"
            }
            
            switch writeStatus {
            case .sharingAuthorized:
                writeMessage = "Authorized for sharing"
            case .sharingDenied:
                writeMessage = "Denied for sharing for sharing"
            case .notDetermined:
                writeMessage = "Not determined yetfor sharing"
            default:
                writeMessage = "Not Authorized for sharing"
            }
            
            // Print the final authorization status for each health type
            print("\(typeName) - Read Status: \(readMessage), Write Status: \(writeMessage)")
        }
    }
}
