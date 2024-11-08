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

    func requestHealthDataPermissions(completion: @escaping (Bool) -> Void) {
        // 요청할 데이터 타입 설정
        let heightType = HKObjectType.quantityType(forIdentifier: .height)!
        let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        let biologicalSexType = HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
        
        let typesToRead: Set = [heightType, weightType, biologicalSexType, dateOfBirthType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit 개인정보 권한 요청 오류: \(error.localizedDescription)")
            }
            completion(success)
        }
    }

    func fetchUserHeight(completion: @escaping (Double?) -> Void) {
        guard let heightType = HKObjectType.quantityType(forIdentifier: .height) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            if let result = results?.first as? HKQuantitySample {
                let heightInMeters = result.quantity.doubleValue(for: HKUnit.meter())
                completion(heightInMeters * 100) // cm 단위로 변환
            } else {
                completion(nil)
            }
        }
        healthStore.execute(query)
    }

    func fetchUserWeight(completion: @escaping (Double?) -> Void) {
        guard let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, _ in
            if let result = results?.first as? HKQuantitySample {
                let weightInKg = result.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                completion(weightInKg)
            } else {
                completion(nil)
            }
        }
        healthStore.execute(query)
    }

    /*
    // 나중에 개인별로 칼로리 계산할때 사용할듯 현재버전에서는 필요없음
    func fetchUserAge(completion: @escaping (Int?) -> Void) {
        do {
                let birthDate = try healthStore.dateOfBirthComponents() 
                let calendar = Calendar.current
                let ageComponents = calendar.dateComponents([.year], from: birthDate.date!, to: Date())
                completion(ageComponents.year)
           
        } catch {
            print("HealthKit에서 생년 정보를 가져올 수 없음: \(error)")
            completion(nil)
        }
    }

    func fetchUserGender(completion: @escaping (String?) -> Void) {
        do {
            let biologicalSex = try healthStore.biologicalSex()
            switch biologicalSex.biologicalSex {
            case .male:
                completion("male")
            case .female:
                completion("female")
            default:
                completion(nil)
            }
        } catch {
            print("HealthKit에서 성별 정보를 가져올 수 없음: \(error)")
            completion(nil)
        }
    }
// Usage:
//    requestHealthDataPermissions { authorized in
//        if authorized {
//            fetchUserHeight { height in
//                print("Height: \(height ?? 0) cm")
//            }
//            
//            fetchUserWeight { weight in
//                print("Weight: \(weight ?? 0) kg")
//            }
//            
//            fetchUserAge { age in
//                print("Age: \(age ?? 0) years")
//            }
//            
//            fetchUserGender { gender in
//                print("Gender: \(gender ?? "unknown")")
//            }
//        } else {
//            print("HealthKit 권한이 거부되었습니다.")
//        }
//    }
*/
    
}
