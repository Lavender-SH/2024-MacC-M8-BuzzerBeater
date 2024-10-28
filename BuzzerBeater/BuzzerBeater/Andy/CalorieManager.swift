//
//  CalorieManager.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/28/24.
//

import Foundation
import SwiftUI
import HealthKit

class CalorieManager: ObservableObject {
    public static let shared = CalorieManager()
    let healthStore = HKHealthStore()
    let suiteName = "com.lavender.buzzbeater"
    
    @Published var calorieBurned: Double = 0.0
    @Published var remainingTime: Double = 0.0
    
    private var timer: Timer?
    
    init() {
        requestAuthorization()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let read = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.quantityType(forIdentifier: .stepCount)!, HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!, HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!])
        let share = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.quantityType(forIdentifier: .stepCount)!, HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!, HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!])
        
        
        healthStore.requestAuthorization(toShare: share, read: read) { success, error in
            if !success {
                print("HealthKit authorization failed: \(String(describing: error?.localizedDescription))")
            } else {
                print("HealthKit authorized")
            }
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            if self.remainingTime > 0 {
                self.updateData()
            } else {
                self.timer?.invalidate()
            }
        }
    }
    
    func updateData() {
        let startDate = loadStartTimeFromUserDefaults()
        let endDate = loadEndTimeFromUserDefaults()
        print("updateData- startDate  \(startDate)")
        print("updateData- endDate   \(endDate)")
        if Date() > endDate {
            timer?.invalidate()
        }
        fetchCalorieBurned(startDate: startDate.addingTimeInterval(-60*10), endDate: Date()) { calories in
            DispatchQueue.main.async {
                self.calorieBurned = calories + 30 //for debugging purpose
                print("calrorie Burned \(self.calorieBurned)")
                self.remainingTime = endDate.timeIntervalSince1970 - Date().timeIntervalSince1970
                print("remaining Time \(self.remainingTime)")
               
            }
        }
    }
    
    func fetchCalorieBurned(startDate: Date, endDate: Date, completion: @escaping (Double) -> Void) {
        
        guard let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0.0)
            return
        }
        print("fetchCalorieBurned- startDate \(startDate))")
        print("fetchCalorieBurned- endDate \(endDate))")
        let predicate = HKQuery.predicateForSamples(withStart: startDate , end: endDate, options: .strictEndDate)
        
        let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            
            if let sum = result?.sumQuantity() {
                let calories = sum.doubleValue(for: .kilocalorie())
                print("fetchCalorieBurned - closure\(calories)")
              
               
                completion(calories)
            
            } else {
               //   self.calorieBurned  = 40
                let calories = 0
                completion(Double(calories))
            }
        }
        
        self.healthStore.execute(query)
        
        print("fetchCalorieBurned - finish Query")
        
    }
    func saveStartTimeToUserDefaults(startTime: Date) {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.set(startTime, forKey: "startTime")
    }
    func loadStartTimeFromUserDefaults() -> Date {
        let userDefaults = UserDefaults(suiteName: suiteName)
        return userDefaults?.object(forKey: "startTime") as? Date ?? Date()
    }

    func saveEndTimeToUserDefaults(endTime: Date) {
        let userDefaults = UserDefaults(suiteName:suiteName)
        userDefaults?.set(endTime, forKey: "endTime")
    }
    func loadEndTimeFromUserDefaults() -> Date {
        let userDefaults = UserDefaults(suiteName: suiteName)
        return userDefaults?.object(forKey: "endTime") as? Date ?? Date()
    }
}
