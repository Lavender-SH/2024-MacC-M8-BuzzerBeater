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
    let  healthStore =  HealthService.shared.healthStore
    let minDegree = 0.001
    @State private var region : MKCoordinateRegion?
    @State private var routePoints: [CLLocation] = []
    @State private var coordinates: [CLLocationCoordinate2D] = []
    @State private var position: MapCameraPosition = .automatic
    
    init(workout: HKWorkout) {
        self.workout = workout
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742),
            span: MKCoordinateSpan(latitudeDelta: minDegree, longitudeDelta: minDegree)
        )
    }
    
    var body: some View {
        VStack{
            Text("workout starting at \(workout.startDate) ending at \(workout.endDate)")
            
            Map(position: $position, interactionModes: [.all] ){
                MapPolyline(coordinates: coordinates)
                    .stroke(Color.blue, lineWidth: 4)
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
            getRouteFrom(workout: workout)
            coordinates = routePoints.map { $0.coordinate }
            if let region = self.region {
                position = .region(region)
            }
        }
        .onChange(of: routePoints) { _ , _ in
            coordinates = routePoints.map { $0.coordinate }
        }
        
    }
    
    public func getRouteFrom(workout: HKWorkout) {
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
                    
                    print("mapspan in MapPathView: \(mapSpan)")
                    // Update the map region and plot the route on the main thread
                    DispatchQueue.main.async {
                        self.region = MKCoordinateRegion(center: mapCenter, span: mapSpan)
                        // Add all locations to routePoints
                        self.routePoints.append(contentsOf: locations)
                        // Stop the route locations query now that we're done
                        self.healthStore.stop(routeLocationsQuery)
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
}
