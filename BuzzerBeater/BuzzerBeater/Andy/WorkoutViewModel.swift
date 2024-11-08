//
//  WorkoutViewModel.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/31/24.
//

import HealthKit
import SwiftUI
import Foundation

//struct WorkoutData: Identifiable, Sendable {
//    let id : UUID
//    let workout: HKWorkout
//    let startDate: Date
//    let endDate: Date
//    let duration: TimeInterval
//    let totalEnergyBurned: Double
//    let totalDistance: Double
//}


@MainActor
class WorkoutViewModel: NSObject, ObservableObject {
    static let shared = WorkoutViewModel()
    
//    @Published var workouts: [WorkoutData] = []
    @Published var workouts: [HKWorkout] = []
    let healthStore = HealthService.shared.healthStore
    var appIdentifier: String?
    
    func fetchWorkout(appIdentifier: String) async {
        self.workouts.removeAll()
        
        let workoutType = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .sailing)
        let appIdentifierPredicate = HKQuery.predicateForObjects(withMetadataKey: "AppIdentifier", operatorType: .equalTo, value: appIdentifier)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, appIdentifierPredicate])
        let sortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: sortDescriptors) { [weak self] (query, results, error) in
                
                if let error = error {
                    print("Error fetching workouts: \(error.localizedDescription)")
                    continuation.resume() // 작업 종료 알림
                    return
                }
                guard let results = results as? [HKWorkout] else {
                    print("No workouts found or results are not of type HKWorkout.")
                    continuation.resume() // 작업 종료 알림
                    return
                }
                
                print("Found workouts : \(results.count) \(results.debugDescription).")
//                let convertedWorkouts = results.map { workout in
//                    WorkoutData(
//                        id : workout.uuid,
//                        workout: workout,
//                        startDate: workout.startDate,
//                        endDate: workout.endDate,
//                        duration: workout.duration,
//                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0,
//                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0
//                    )
//                }
                
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.workouts = results
                    print("fetchWorkout workouts: \(self.workouts)")
                }
                
                for workout in results {
                    Task{
                        await self?.fetchWorkoutRoute(for: workout)
                        
                    }
                    
                }
                continuation.resume() // 모든 작업이 완료된 후에 종료 알림
            }
            
            healthStore.execute(query)
        }
        
    }
    // workout 과 1:1 매칭이 되는   workoutRoute가져오기
    func fetchWorkoutRoute(for workout: HKWorkout) async -> Result<HKWorkoutRoute, Error> {
        await withCheckedContinuation { continuation in
            
            let routePredicate = HKQuery.predicateForObjects(from: workout)
            let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: routePredicate, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, newAnchor, error in
                guard let routes = samples as? [HKWorkoutRoute], error == nil else {
                    print("Error fetching route: \(String(describing: error))")
                    continuation.resume(returning: .failure(error ?? NSError(domain: "Error fetching route", code: 0, userInfo: nil) ) )
                    return
                }
                
                // Route가 성공적으로 조회되었는지 확인
                if let firstRoute = routes.first {
                    // Fetch locations for the first route
                    
                    Task {
                        let workoutFromfetch  = await self.findWorkoutForRoute(firstRoute, healthStore: self.healthStore)
                        print("workout: \(String(describing: workout)) ")
                        print("workoutFrom:\(String(describing: workoutFromfetch))" )
                        print("route: \(firstRoute) to crossCheck route")
                        
                        do {
                            try await self.fetchRouteLocations(for: firstRoute)
                        } catch {
                            print("Error fetching route locations: \(error)")
                        }
                        
                        continuation.resume(returning: .success(firstRoute)) // Resume only after fetchRouteLocations
                    }
                } else {
                    continuation.resume(returning: .failure(error ?? NSError(domain: "", code: 0, userInfo: nil)))
                }
            }
            healthStore.execute(routeQuery)
        }
    }

    func findWorkoutForRoute(_ targetRoute: HKWorkoutRoute, healthStore: HKHealthStore)  async -> HKWorkout? {
        var foundWorkout: HKWorkout?
        return await withCheckedContinuation { continuation in
            // Step 1: Fetch all workouts
            let workoutQuery = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: nil, // No predicate to fetch all workouts
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil)   { query, results, error in
                    
                    guard let workouts = results as? [HKWorkout], error == nil else {
                        print("Error fetching workouts: \(error?.localizedDescription ?? "Unknown error")")
                        return continuation.resume(returning: nil)
                    }
                   // Step 2: Iterate through workouts to find one with the target route
                    let group = DispatchGroup()
                 
                    for workout in workouts {
                        group.enter()
                        // Query routes for this workout
                        let routePredicate = HKQuery.predicateForObjects(from: workout)
                        let routeQuery = HKSampleQuery(
                            sampleType: HKSeriesType.workoutRoute(),
                            predicate: routePredicate,
                            limit: HKObjectQueryNoLimit,
                            sortDescriptors: nil) { routeQuery, routeResults, routeError in
                                
                                if let routes = routeResults as? [HKWorkoutRoute], routes.contains(where: { $0.uuid == targetRoute.uuid }) {
                                    // Found the workout with the target route
                                    // 의미없는데중복으로 해봄..
                                   
                                        DispatchQueue.main.async {
                                            foundWorkout = workout
                                        }
                                    
                                }
                                group.leave()
                        }
                        
                        healthStore.execute(routeQuery)
                    }
                    
                    // Wait until all route queries are complete
                    group.notify(queue: .main) {
                        DispatchQueue.main.async {
                            continuation.resume(returning: foundWorkout)
                        }
                    }
                }
            
            healthStore.execute(workoutQuery)
        }
    }


    
    func fetchRouteLocations(for route: HKWorkoutRoute) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let locationQuery = HKWorkoutRouteQuery(route: route) { (query, locations, done, error) in
                if let error = error {
                    print("Error fetching route locations: \(error.localizedDescription)")
                    continuation.resume(throwing: LocationError.queryFailed(error)) // Resume with the specific error
                    return
                }
                
                guard let locations = locations else {
                    print("No locations found.")
                    // Using the custom error for no locations
                    continuation.resume(throwing: LocationError.noLocations) // Resume with the custom error
                    return
                }
                
                print("---------- fetchRouteLocations for route: \(route.uuid) ----------")
                print("startDate: \(route.startDate.formatted()) endDate: \(route.endDate.formatted()) locations: \(locations.count)")
                
                for location in locations {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yy-MM-dd HH:mm:ss"
                    let formattedDate = dateFormatter.string(from: location.timestamp)
                    
                    print("time: \(formattedDate) lat: \(String(format: "%.4f", location.coordinate.latitude)), lon: \(String(format: "%.4f", location.coordinate.longitude))")
                }
                print("----------------------------------end ----------------------------------")
                
                // If done, resume the continuation to end processing
                if done {
                   return continuation.resume()
                }
            }
            
            healthStore.execute(locationQuery) // Execute the query
        }
    }
    
    
    
    
    // 나중에 개인별로 Total calorie 계산할때 사용할것 지금 버전은 필요가 없음
    /*
    
    func calculateTotalEnergyBurned(startDate: Date, endDate: Date, completion: @escaping (HKQuantity?) -> Void) {
        let healthStore = HKHealthStore()
        let activeEnergyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // 운동 중 누적 activeEnergyBurned 값을 쿼리합니다.
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let statisticsQuery = HKStatisticsQuery(quantityType: activeEnergyBurnedType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let activeEnergyBurned = result?.sumQuantity() else {
                completion(nil)
                return
            }
            
            // 사용자의 BMR을 가져와서 기초 대사 에너지를 계산합니다.
            DispatchQueue.main.async {
                let bmrPerDay = self.fetchBMR() // BMR을 가져오는 사용자 정의 함수 (하루 단위)
                let workoutDuration = endDate.timeIntervalSince(startDate) / 86400 // 운동 기간을 하루로 변환
                let basalEnergyBurned = bmrPerDay * workoutDuration // BMR에 운동 시간 비율을 곱합니다.
                
                let totalEnergyBurned = activeEnergyBurned.doubleValue(for: .kilocalorie()) + basalEnergyBurned
                let totalEnergyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: totalEnergyBurned)
                
                completion(totalEnergyQuantity)
            }
        }
        
        healthStore.execute(statisticsQuery)
    }

    // 사용자의 BMR을 계산하거나 가져오는 예시 (사용자의 몸무게, 나이 등을 고려)
    //  추후 수정
    
    func fetchBMR() -> Double {
        // 기초 대사율(BMR) 계산 (단위: kcal/day)
        // 예: 몸무게, 나이, 성별 등의 변수에 따라 조정
        return 1500.0 // 예시 값
    }
    
    func calculateBMR(weightInKg: Double, heightInCm: Double, ageInYears: Int, gender: String) -> Double {
        // Harris-Benedict 공식
        if gender.lowercased() == "male" {
            // 남성용 BMR 공식
            return 88.362 + (13.397 * weightInKg) + (4.799 * heightInCm) - (5.677 * Double(ageInYears))
        } else {
            // 여성용 BMR 공식
            return 447.593 + (9.247 * weightInKg) + (3.098 * heightInCm) - (4.330 * Double(ageInYears))
        }
    }

//    // 예제 사용
//    let weight = 70.0   // 체중(kg)
//    let height = 175.0  // 키(cm)
//    let age = 25        // 나이(년)
//    let gender = "male" // 성별
//
//    let bmr = calculateBMR(weightInKg: weight, heightInCm: height, ageInYears: age, gender: gender)
//    print("기초 대사율(BMR): \(bmr) kcal/day")
    */

}


