//
//  MapPathView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/4/24.
//
import CoreLocation
import MapKit
import SwiftUI
import HealthKit

struct MapPathView: View {
    var workout: HKWorkout // or the appropriate type for your workout data
    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.0025
    
    @State private var region: MKCoordinateRegion? = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Default center
        span: MKCoordinateSpan(latitudeDelta: 0.0025, longitudeDelta: 0.0025) // Default span
    )

    @State var routePoints: [CLLocation] = []
    @State var coordinates: [CLLocationCoordinate2D] = []
    @State var velocities: [CLLocationSpeed] = []
    @State var position: MapCameraPosition = .automatic
    @State var totalEnergyBurned: Double = 0
    @State var totalDistance: Double = 0
    @State var activeEnergyBurned: Double = 0
    @State var duration : TimeInterval = 0
    
    let workoutManager = WorkoutManager.shared
    
    init(workout: HKWorkout) {
        self.workout = workout
        self.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742),
                span: MKCoordinateSpan(latitudeDelta: minDegree, longitudeDelta: minDegree)
            )
       
    }
    
    var body: some View {
        
        VStack{
            Text("\(formattedDuration(duration))").font(.caption2)
            Text("Total Distance: \(formattedDistance(totalDistance))")
                .font(.caption2)
            Text("Total Energy Burned: \(formattedEnergyBurned(totalEnergyBurned))")
                .font(.caption2)
            Text("Active Energy Burned: \(formattedEnergyBurned(activeEnergyBurned))")
                .font(.caption2)
            
            Map(position: $position, interactionModes: [.all] ){
                if coordinates.count >= 2 {
                    ForEach(0..<coordinates.count - 1, id: \.self) { index in
                        let start = coordinates[index]
                        let end = coordinates[index + 1]
                    
                        let velocity = velocities[index]
                        let maxVelocity = velocities.max() ?? 10.0
                        let minVelocity = velocities.min() ?? 0.0
                        let color = calculateColor(for: velocity, minVelocity: minVelocity, maxVelocity: maxVelocity)
                        
                        MapPolyline(coordinates: [start, end])
                            .stroke(color, lineWidth: 5)
                    }
                }
                
                 MapPolyline(coordinates: coordinates)
                     .stroke(Color.cyan, lineWidth: 1)
                
            }
            .mapControls{
                MapUserLocationButton()
                MapCompass()
#if !os(watchOS)
                MapScaleView()
#endif
            }
        }
        .onAppear{
            DispatchQueue.main.async {
                loadWorkoutData()
            }
            let totaldistance = workout.metadata?["TotalDistance"]  as? Double ?? 0.0
            self.totalDistance = totaldistance
            self.workoutManager.fetchTotalEnergyBurned(for: workout) { totalEnergyBurned in
                if let totalEnergyBurned  = totalEnergyBurned{
                    self.totalEnergyBurned = totalEnergyBurned.doubleValue(for: .kilocalorie())
                    print("totalEnergyBurned fetched successfully \(totalEnergyBurned)")
                } else {
                    print("totalEnergyBurned is nil")
                }
            }
            
            self.workoutManager.fetchActiveEnergyBurned(startDate: workout.startDate, endDate: workout.endDate) { activeEnergyBurned in
                if let activeEnergyBurned  = activeEnergyBurned{
                    self.activeEnergyBurned = activeEnergyBurned.doubleValue(for: .kilocalorie())
                    print("activeEnergyBurned fetched successfully \(activeEnergyBurned)")
                } else {
                    print("activeEnergyBurned is nil")
                }
            }
            self.duration = workout.endDate.timeIntervalSince(workout.startDate)
         
            print("velocities \(velocities.count), coordinates \(coordinates.count) routePoints\(routePoints.count)" )
         
        }
//
//        .onChange(of: routePoints) { _ , _ in
//            DispatchQueue.main.async {
//                loadWorkoutData()
//                if let region = self.region {
//                    position = .region(region)
//                }
//            }
 //        }
        
    }
    
    func calculateColor(for velocity: Double, minVelocity: Double, maxVelocity: Double) -> Color {
        if maxVelocity <= minVelocity {
            return Color.green
        }
        let progress = CGFloat((velocity - minVelocity) / (maxVelocity - minVelocity))
        
        if progress < 0.7 {
            return Color.yellow
        }
        else if progress  >= 0.7 && progress < 0.85 {
            return Color.green
        }
        
        else if progress >= 0.85 {
            return Color.red
        }
        else {
            return Color.blue
        }
    }
    
    public func getRouteFrom(workout: HKWorkout , completion: @escaping () -> Void) {
        let mapDisplayAreaPadding = 1.3
        
        // Create a predicate for objects associated with the workout
        let runningObjectQuery = HKQuery.predicateForObjects(from: workout)
        
        // 1. `routeQuery`: Retrieve all workout route samples associated with the workout.
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: runningObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (routeQuery, samples, deletedObjects, anchor, error) in
            
            guard error == nil else {
                fatalError("The initial query failed.")
            }
            
            // Ensure we have some route samples to work with
            guard samples?.count ?? 0 > 0 else {
                print("samples(route) is empty")
                return
            }
            
            // Assuming the first sample is the route we want to use
            let route = samples?.first as! HKWorkoutRoute
            
            // 2. `routeLocationsQuery`: Retrieve locations from the specific workout route.
            let routeLocationsQuery = HKWorkoutRouteQuery(route: route) { (routeLocationsQuery, locations, done, error) in
                // This block may be called multiple times as location data arrives in chunks.
                if let error = error {
                    print("Error \(error.localizedDescription)")
                    return
                }
                
                guard let locations = locations else {
                    fatalError("*** NIL found in locations ***")
                }
                DispatchQueue.main.async {
                    self.routePoints.append(contentsOf: locations)
                }
                // Extract latitude and longitude values from the locations
                let latitudes = locations.map { $0.coordinate.latitude }
                let longitudes = locations.map { $0.coordinate.longitude }
                
                // Calculate the map region's boundaries
                guard let maxLat = latitudes.max(), let minLat = latitudes.min(),
                      let maxLong = longitudes.max(), let minLong = longitudes.min() else {
                    return
                }
                if done {
                    // Calculate the center and span for the map region
                    let mapCenter = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLong + maxLong) / 2)
                    let mapSpan = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * mapDisplayAreaPadding , self.minDegree), longitudeDelta: max((maxLong - minLong) * mapDisplayAreaPadding , self.minDegree))
                    self.healthStore.stop(routeLocationsQuery)
                    print("mapspan in MapPathView: \(mapSpan)")
                    // Update the map region and plot the route on the main thread
                    DispatchQueue.main.async {
                        self.region = MKCoordinateRegion(center: mapCenter, span: mapSpan)
                        // Stop the route locations query now that we're done
                        completion()
                     
                        if let region = self.region {
                            position = .region(region)
                        }
                        
                        
                        print("velocities \(velocities.count), coordinates \(coordinates.count) routePoints\(routePoints.count) in the getRouteFrom" )
                    }
                   
                }
            }
            // Execute the `routeLocationsQuery` to get location points within the route
            healthStore.execute(routeLocationsQuery)
        }
        routeQuery.updateHandler = { (routeQuery: HKAnchoredObjectQuery, samples: [HKSample]?, deleted: [HKDeletedObject]?, anchor: HKQueryAnchor?, error: Error?) in
            guard error == nil else {
                print("The update failed.")
                return
            }
            // Process updates or additions here if needed
        }
        // Execute the `routeQuery` to fetch workout route samples
        healthStore.execute(routeQuery)
    }
    
    func loadWorkoutData() {
        getRouteFrom(workout: workout) {
            coordinates = routePoints.map { $0.coordinate}
            velocities = routePoints.map { $0.speed }
        }
    }
    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
   
    func formattedDistance(_ distance: Double?) -> String {
        // distance가 nil이 아니면, 미터 단위로 값을 가져와서 킬로미터로 변환
        guard let distance = distance else { return "0.00 km" }
        
        // 미터 단위로 값을 가져온 후, 1000으로 나누어 킬로미터로 변환
        let kilometer = distance / 1000
        
        print("kilo: \(kilometer)")
        // 킬로미터 단위로 포맷팅해서 반환
        return String(format: "%.2f km", kilometer)
    }
    func formattedEnergyBurned(_ calories: Double?) -> String {
        // distance가 nil이 아니면, 미터 단위로 값을 가져와서 킬로미터로 변환
        guard let calories = calories else { return "0.00 Kcal" }
        let caloriesInt = Int( calories )
        print("Kcal \(caloriesInt)")
        // 킬로미터 단위로 포맷팅해서 반환
        return String(format: "%d Kcal", caloriesInt)
    }
}
