//
//  Misc.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/28/24.
//

//
//  Misc.swift
//  LiveWalkAndCal
//
//  Created by Giwoo Kim on 6/19/24.
//


/*
import Foundation
import HealthKit
import SwiftUI


func saveIsWidgetActiveToUserDefaults(isWidgetActive: Bool) {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    userDefaults?.set(isWidgetActive , forKey: "isWidgetActive")
}
func loadIsWidgetActiveFromUserDefaults() -> Bool {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    return userDefaults?.bool(forKey: "isWidgetActive") ?? false
}
func saveStartTimeToUserDefaults(startTime: Date) {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    userDefaults?.set(startTime, forKey: "startTime")
}
func loadStartTimeFromUserDefaults() -> Date {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    return userDefaults?.object(forKey: "startTime") as? Date ?? Date()
}

func saveEndTimeToUserDefaults(endTime: Date) {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    userDefaults?.set(endTime, forKey: "endTime")
}
func loadEndTimeFromUserDefaults() -> Date {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    return userDefaults?.object(forKey: "endTime") as? Date ?? Date()
}
func saveInputCalToUserDefaults(inputCal: Double) {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    userDefaults?.set(inputCal, forKey: "inputCal")
}

func loadInputCalFromUserDefaults() -> Double {
    let userDefaults = UserDefaults(suiteName: "group.com.giwoo.andy.LiveAndWalk")
    return userDefaults?.double(forKey: "inputCal") ?? 0.0
}

func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

extension NumberFormatter {
    static var integerFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.maximumIntegerDigits = 3  // 최대 3자리 숫자
        return formatter
    }
}

func requestAuthorization() {
    let healthStore = HealthStoreProvider().healthStore
       if HKHealthStore.isHealthDataAvailable() {
           let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
           let dataTypes: Set = [energyType]
           
           healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) in
               if success {
                   fetchActiveEnergyBurned()
               } else {
                   print("HealthKit 권한 요청 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
               }
           }
       }
   }
   
func fetchActiveEnergyBurned() {
        let healthStore = HKHealthStore()
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let now = Date()
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -10, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: oneHourAgo, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, result, error) in
            guard let result = result, let sum = result.sumQuantity() else {
                print("데이터를 가져오는 중 오류 발생: \(error?.localizedDescription ?? "알 수 없는 오류")")
                return
            }
            
            let energyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
            DispatchQueue.main.async {
                print("최근 1시간 동안 소모한 활동 에너지: \(Int(energyBurned)) kcal")
            }
        }
        
        healthStore.execute(query)
    }

*/
