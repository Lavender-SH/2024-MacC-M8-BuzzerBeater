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
    
    let workoutManager = WorkoutManager.shared
    @EnvironmentObject var mapPathViewModel  : MapPathViewModel
    var workout: HKWorkout? // or the appropriate type for your workout data
    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    @State var  isDataLoaded: Bool = false
    
   var isModal: Bool
    
    init(workout: HKWorkout?, isModal: Bool = false) {
         
        
        self.workout = workout
        self.isModal = isModal
    }
    
    var body: some View {
        
        VStack{
            if isDataLoaded {
                ZStack(alignment: .top) {
                    
                    Map(position: $mapPathViewModel.position, interactionModes: [.all] ){
//                        if mapPathViewModel.coordinates.count >= 2 {
//                            // 예시: CLLocation 객체를 포함한 coordinates 배열의 경우
//                            let maxVelocity = mapPathViewModel.velocities.max() ?? 10.0
//                            let minVelocity = mapPathViewModel.velocities.min() ?? 0.0
//
//                            ForEach(0..<mapPathViewModel.coordinates.count - 1, id: \.self) { index in
//                                let start = mapPathViewModel.coordinates[index]
//                                let end = mapPathViewModel.coordinates[index + 1]
//                                let velocity = ( mapPathViewModel.velocities[index] + mapPathViewModel.velocities[index + 1] ) / 2.0
//                                let color = calculateColor(for: velocity, minVelocity: minVelocity, maxVelocity: maxVelocity)
//                                
//                                MapPolyline(coordinates: [start, end])
//                                    .stroke(color, lineWidth: 5)
//                            }
//                        }
                        
                        MapPolyline(coordinates: mapPathViewModel.coordinates)
                            .stroke(Color.cyan, lineWidth: 4)
                        
                    }
                    .mapControls{
                        VStack{
                            MapUserLocationButton()
                            MapCompass()
                        }
                        
#if !os(watchOS)
                        MapScaleView()
#endif
                    }          .ignoresSafeArea(.all)
                    
                    
                    
                    //                    VStack{
                    //#if !os(watchOS)
                    //                        Text("\(formattedDuration(duration))").font(.caption2)
                    //                        Text("Total Distance: \(formattedDistance(totalDistance))")
                    //                            .font(.caption2)
                    //                        Text("Total Energy Burned: \(formattedEnergyBurned(totalEnergyBurned))")
                    //                            .font(.caption2)
                    //                        Text("MaxSpeed: \(maxSpeed) --  maxVelocity \(velocities.max() ?? 10)")
                    //                            .font(.caption2)
                    //
                    //#endif
                    //
                    //
                    //#if os(watchOS)
                    //                        Text("\(formattedDuration(duration))").font(.caption2)
                    //
                    //#endif
                    //
                    //                    }.padding(.top, 50)
                    
                    if isModal {
                        VStack {
                            ZStack {
                                Button(action: {
                                    print("Button tapped!")
                                }) {
                                    Text("")
                                }
                                .frame(width: 300, height: 90)
                                .background(Color.gray.opacity(0.01))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white)
                                    .frame(width: 150, height: 5)
                            }
                            .padding(.top, -10)
                            
                            Spacer()
                        }

                    }
                }
            }
            
            else {
                //Text("Sky is Blue and Water is Clear!!!")
                ProgressView()
            }
            
        }
        .task{
            if mapPathViewModel.workout != self.workout {
                print("mapPathViewModel will load data in the mapPathView \n workout: \(String(describing: self.workout))    \n mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout))" )
                if let workout = self.workout {
                    await  mapPathViewModel.loadWorkoutData(workout: workout)
                    self.mapPathViewModel.workout = self.workout //중복이지만 다시 작성
                    print("mapPathViewModel after loadWorkoutData \(mapPathViewModel.workout) \(mapPathViewModel.isDataLoaded)")
                    isDataLoaded = true
                }
                else {
                    print("self.workout in the mapPathView is nil")
                    isDataLoaded = true
                }
            } else {
                isDataLoaded = true
                print("mapPathViewModel will not load data in the mapPathViw \n workout: \(String(describing: self.workout)) \n    mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout))" )
            }
            
        }
        .ignoresSafeArea()
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
