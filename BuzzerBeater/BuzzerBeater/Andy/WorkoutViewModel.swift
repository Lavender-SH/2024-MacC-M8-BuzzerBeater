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
    let id : UUID
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
        
        self.workouts.removeAll()
        
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
                let convertedWorkouts = results.map { workout in
                    WorkoutData(
                        id : workout.uuid,
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
                        print("workoutFrom:\(workoutFromfetch)" )
                        print("route: \(firstRoute) to crossCheck route")
                        await self.fetchRouteLocations(for: firstRoute)
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
                 
                    let accessQueue = DispatchQueue(label: "accessQueue")
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
                                    accessQueue.async {
                                        foundWorkout = workout
                                    }
                                }
                                group.leave()
                        }
                        
                        healthStore.execute(routeQuery)
                    }
                    
                    // Wait until all route queries are complete
                    group.notify(queue: .main) {
                        continuation.resume(returning: foundWorkout)
                    }
                }
            
            healthStore.execute(workoutQuery)
        }
    }

//    아래 함수는 잘 안됨..아래에서 위로 검색자체가 안되는듯함. route가지고 workout을 찾을수없음 대신에 findWorkoutForRoute로 대체함
//    func fetchWorkoutRouteAndDetails(for route: HKWorkoutRoute, healthStore: HKHealthStore)  async ->HKWorkout?  {
//     
//         let workoutRouteID = route.uuid
//         
//         return await withCheckedContinuation { continuation in
//            // Fetch the workout that corresponds to the workout route
//             print("Fetching workoutRoute: \(workoutRouteID)")
//             let predicate = HKQuery.predicateForObject(with: workoutRouteID)
//             let workoutQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(),
//                                              predicate: predicate,
//                                              limit: 1,
//                                              sortDescriptors: nil) { query, results, error in
//                 guard error == nil else {
//                    print("Error fetching workout: \(error!.localizedDescription)")
//                    return continuation.resume(returning: nil)
//                }
//                 print("fectched results: \(results) \(results?.count)")
//                 
//                if let workouts = results as? [HKWorkout], let workout = workouts.first {
//                    // Print workout details
//                    print("Workout Type: \(workout.workoutActivityType)")
//                    print("Duration: \(workout.duration) seconds")
//                    print("Start Date: \(workout.startDate)")
//                    print("End Date: \(workout.endDate)")
//                    print("Total Energy Burned: \(String(describing: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()))) kcal")
//                    print("Total Distance: \(String(describing: workout.totalDistance?.doubleValue(for: .meter()))) meters")
//                    
//                    continuation.resume(returning: workout)
//                } else {
//                    print("No workout found for this route.")
//                    continuation.resume(returning: nil)
//                }
//                
//            }
//            
//            healthStore.execute(workoutQuery)
//        }
//    }
    func fetchRouteLocations(for route: HKWorkoutRoute) async {
        await withCheckedContinuation { continuation in
            let locationQuery = HKWorkoutRouteQuery(route: route) { (query, locations, done, error) in
                guard let locations = locations, error == nil else {
                    print("Error fetching route locations: \(String(describing: error))")
                    continuation.resume()
                    return
                }
                print("---------- fetchRouteLocations for route: \(route.uuid) ----------")
                print("startDate: \(route.startDate.formatted()) endDate:\(route.endDate.formatted())  locations : \(locations.count) ")
               
                for location in locations {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yy-MM-dd HH:mm:ss" // Customize the format as needed
                    let formattedDate = dateFormatter.string(from: location.timestamp)

                    print("time: \(formattedDate) lat: \(String(format: "%.4f", location.coordinate.latitude)), lon: \(String(format: "%.4f", location.coordinate.longitude))")

                }
                
                print("----------------------------------end ----------------------------------")
                continuation.resume()
            }
            healthStore.execute(locationQuery)
          
        }
    }
}
