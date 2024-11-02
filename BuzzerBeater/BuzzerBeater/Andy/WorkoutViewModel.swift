//
//  WorkoutViewModel.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/31/24.
//

import HealthKit
import SwiftUI
import WorkoutKit
import Foundation

struct WorkoutData: Identifiable, Sendable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalEnergyBurned: Double
    let totalDistance: Double
}

@MainActor
class WorkoutViewModel: NSObject, ObservableObject {
    static let shared = WorkoutViewModel()
    
    @Published var workouts: [WorkoutData] = []
    
    let healthStore = HealthService.shared.healthStore
    var appIdentifier: String?
    
    func fetchWorkout(appIdentifier: String) async {
        let workoutType = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .sailing)
        workouts.removeAll()
        
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
                
                print("results workouts : \(results)")
                
                guard let results = results as? [HKWorkout] else {
                    print("No workouts found or results are not of type HKWorkout.")
                    continuation.resume() // 작업 종료 알림
                    return
                }
                print("Found workouts : \(results.count) .")
                
                if let workout = results.first {
                    print("Found Workout: \(workout.startDate) to \(workout.endDate)")
                    //Task 사용: 새로운 비동기 작업을 생성하여 현재의 작업을 차단하지 않고 독립적으로 실행되도록 하고 서스펜딩상태로 돌입.
                    Task{
                      
                            await self?.fetchWorkoutRoute(for: workout)
                      
                    }
                }
                
                let convertedWorkouts = results.map { workout in
                    WorkoutData(
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0
                    )
                }
                
        
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.workouts = convertedWorkouts
                    print("fetchWorkout workouts: \(self.workouts)")
                }
                continuation.resume() // 모든 작업이 완료된 후에 종료 알림
            }
            
            healthStore.execute(query)
        }
        
    }
    // workout 과 1:1 매칭이 되는   workoutRoute가져오기
    func fetchWorkoutRoute(for workout: HKWorkout) async   -> Result<HKWorkoutRoute, Error> {
        await withCheckedContinuation { continuation in
            
            let routePredicate = HKQuery.predicateForObjects(from: workout)
            let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: routePredicate, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, newAnchor, error in
                guard let routes = samples as? [HKWorkoutRoute], error == nil else {
                    print("Error fetching route: \(String(describing: error))")
                    continuation.resume(returning: .failure(error ?? NSError(domain: "", code: 0, userInfo: nil) ) )
                    return
                }
                
                // Route가 성공적으로 조회되었는지 확인
              
                print("Route data count: \(routes.count)")
                if let firstRoute = routes.first {
                    // Fetch locations for the first route
                    Task {
                        await self.fetchRouteLocations(for: firstRoute)
                        continuation.resume(returning: .success(firstRoute)) // Resume only after fetching route locations
                    }
                } else {
                    continuation.resume(returning: .failure(error ?? NSError(domain: "", code: 0, userInfo: nil)))
                }
            }
            healthStore.execute(routeQuery)
        }
    }
    
    func fetchRouteLocations(for route: HKWorkoutRoute) async {
        await withCheckedContinuation { continuation in
            let locationQuery = HKWorkoutRouteQuery(route: route) { (query, locations, done, error) in
                guard let locations = locations, error == nil else {
                    print("Error fetching route locations: \(String(describing: error))")
                    continuation.resume()
                    return
                }
                
                print("Fetched locations : \(locations.count)")
                for location in locations {
                    print("time: \(location.timestamp.formatted()) Location:\(location.coordinate.latitude), \(location.coordinate.longitude) ")
                }
                continuation.resume()
            }
            healthStore.execute(locationQuery)
          
        }
    }
}
