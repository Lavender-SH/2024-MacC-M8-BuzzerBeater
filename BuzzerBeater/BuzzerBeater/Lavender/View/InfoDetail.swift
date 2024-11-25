//
//  InfoDetail.swift
//  BuzzerBeater
//
//  Created by 이승현 on 11/13/24.
//  revised by Andy .task {}
//   MapPathView( workout: workout, isModal: true).environmentObject(mapPathViewModel)

import Foundation
import SwiftUI
import Charts
import MapKit
import HealthKit
import CoreLocation
import Charts

struct InfoDetail: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isMapModalPresented = false
    let workoutManager = WorkoutManager.shared
    var workout: HKWorkout?
    @State private var isHelpModalPresented = false


    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    @State private var region: MKCoordinateRegion?
    
   
    @State var activeEnergyBurned: Double = 0
    @State var isDataLoaded : Bool = false
    
    
    @State var totalEnergyBurned: Double = 0
    @State var totalDistance: Double = 0
    @State var maxSpeed : Double = 0
    @State var duration : TimeInterval = 0
    @State var startDate: Date?
    @State var endDate: Date?
    @State var locationName: String = "Loading location..."
    
    @StateObject var mapPathViewModel = MapPathViewModel()
    
    init(workout: HKWorkout) {
   
        self.workout = workout
        
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        List {
            Section {
                HStack(spacing: 20) {
                    InfoIcon()
                        .frame(width: 80, height: 80)
                    
                    VStack(alignment: .leading) {
                        Text("Dinghy Yacht")
                            .font(.system(size: 25).bold())
                            .fontDesign(.rounded)
                            .padding(.bottom, 5)
                        if let startDate = mapPathViewModel.workout?.startDate, let endDate = mapPathViewModel.workout?.endDate {
                            Text("\(formattedTime(startDate)) - \(formattedTime(endDate))")
                                .font(.system(size: 20).bold())
                                .foregroundColor(.secondary)
                                .fontDesign(.rounded)
                                .padding(.bottom, 5)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                            //Text("Pohang City")
                            Text(locationName)
                                .font(.system(size: 18).bold())
                                .fontDesign(.rounded)
                                .foregroundColor(.secondary)
                                .onAppear{
                                

                                    let coordinate = CLLocationCoordinate2D(latitude: 36.017470189362115, longitude: 129.32224097538742)
                                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

                                    fetchLocationName(for: mapPathViewModel.routePoints.first ?? location )
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 5)
            }
            .listRowBackground(Color.clear)
            
            Section(
                header: Text("Navigation Details")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .textCase(nil)
            ) {
                if mapPathViewModel.isDataLoaded {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sailing Time")
                            Text(formattedDuration(mapPathViewModel.duration))
                                .font(.title)
                                .foregroundColor(.yellow)
                                .fontDesign(.rounded)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sailing Distance")
                            Text("\(formattedDistance(mapPathViewModel.totalDistance))")
                                .font(.title)
                                .foregroundColor(.cyan)
                                .fontDesign(.rounded)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calories")
                            Text("\(formattedEnergyBurned(mapPathViewModel.totalEnergyBurned))")
                                .font(.title)
                                .foregroundColor(.cyan)
                                .fontDesign(.rounded)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Highest Speed")
                            Text("\(formattedMaxSpeed(mapPathViewModel.velocities.max() ?? 0)) m/s")
                                .font(.title)
                                .foregroundColor(.cyan)
                                .fontDesign(.rounded)
                        }
                    }
                    .padding(1)
                } else {
                    ProgressView("Loading Data...")
                }
            }
            
            Section(
                header: Text("Speed of a Yacht")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                    .fontDesign(.rounded)
                    .textCase(nil)
            ) {
                if mapPathViewModel.isDataLoaded {
                    let startTime = mapPathViewModel.routePoints.first?.timestamp ?? Date()
                    let endTime = mapPathViewModel.routePoints.last?.timestamp ?? Date()
                    let totalDurationInSeconds = endTime.timeIntervalSince(startTime)
                    
                    let averageSpeed = mapPathViewModel.velocities.reduce(0, +) / Double(mapPathViewModel.velocities.count)
                    
                    VStack(alignment: .leading, spacing: 8){
                        Text("Average Speed: \(String(format: "%.2f", averageSpeed)) m/s")
                            .font(.headline)
                            .fontDesign(.rounded)
                            .padding(.bottom, 8)
                            .foregroundStyle(.cyan)
                        Chart {
                         

                            ForEach(Array(mapPathViewModel.velocities.enumerated()) , id: \.offset) { index, speed in
                                let timeInSeconds = mapPathViewModel.routePoints[index].timestamp.timeIntervalSince(startTime)
                                LineMark(
                                    x: .value("Time (sec)", timeInSeconds),
                                    y: .value("Speed", speed)
                                )
                                .foregroundStyle(.cyan)
                            }
                        }                                    .frame(height: 130)
                            .chartXScale(domain: 0...totalDurationInSeconds)  // Dynamic x-axis based on total duration
                            .chartXAxis {
                                AxisMarks()
                            }
                    }
                }
            }
            
            Section(header: Text("Navigation Route")
                .font(.title3)
                .bold()
                .fontDesign(.rounded)
                .foregroundColor(.white)
                .textCase(nil)) {
                    // Button to show the map in a modal view
                    Button(action: {
                        isMapModalPresented = true // Present modal when tapped
                    }) {
                        MapPathView( workout: workout, isModal: false)
                            .environmentObject(mapPathViewModel)
                            .frame(height: 250)
                    }
                    .buttonStyle(PlainButtonStyle()) // Disable default button styling
                }
        }
        .padding(.top, -1)
        .sheet(isPresented: $isMapModalPresented) {
            MapPathView( workout: workout, isModal: true)
                .environmentObject(mapPathViewModel)
                .edgesIgnoringSafeArea(.all)
       }
        .task{
            if mapPathViewModel.workout != self.workout {
                print("mapPathViewModel will load data in the InfoDetail \n workout: \(String(describing: self.workout))    \n mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout))" )
                if let workout = self.workout {
                    await  mapPathViewModel.loadWorkoutData(workout: workout)
                    self.mapPathViewModel.workout = self.workout //중복이지만 다시 작성
                    print("mapPathViewModel after loadWorkoutData in the InfoDetail  \(mapPathViewModel.workout) \(mapPathViewModel.isDataLoaded)")
                    isDataLoaded = true
                }
                else {
                    print("self.workout in the in the InfoDetail  is nil")
                    isDataLoaded = true
                }
            } else {
                isDataLoaded = true
                print("mapPathViewModel will not load data in the InfoDetail  \n workout: \(String(describing: self.workout)) \n    mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout))" )
            }
            
        }
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
#if !os(watchOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(formattedDate(startDate))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isHelpModalPresented.toggle() // Toggle the modal state
                    } label: {
                        Image(systemName: "info.circle")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $isHelpModalPresented) {
                HelpModalView()
        }
#endif
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
    
    func formattedMaxSpeed(_ speed: CLLocationSpeed) -> String {
        return String(format: "%.1f", speed)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: date)
    }
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd (EEE)"
        return formatter.string(from: date)
    }
    
    func fetchLocationName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "en_US")) { placemarks, error in
            if let placemark = placemarks?.first, let city = placemark.locality {
                self.locationName = city
            } else {
                self.locationName = "Unknown Location"
            }
        }
    }
    
}
