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

struct Segment {
    let id = UUID()
    let start: CLLocationCoordinate2D
    let end : CLLocationCoordinate2D
    let color : Color
}
struct MapPathView: View {
    
    let workoutManager = WorkoutManager.shared
    @EnvironmentObject var mapPathViewModel  : MapPathViewModel
    var workout: HKWorkout? // or the appropriate type for your workout data
    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    
    @State var  isDataLoaded: Bool = false
    @State var minVelocity: Double = 0.0
    @State var maxVelocity: Double = 10.0
    
    @State var segments : [Segment] =  []
    
    var isModal: Bool
    
    init(workout: HKWorkout?, isModal: Bool = false) {
        self.workout = workout
        self.isModal = isModal
    }
    
    var body: some View {
        
        VStack{
            if isDataLoaded {
                ZStack(alignment: .top) {
                    
                    Map(position: $mapPathViewModel.position, interactionModes: [.zoom] ) {
                        ForEach( 0..<segments.count , id:\.self) { index in
                            
                            // 각 segment의 start, end 좌표를 이용해 경로를 지도에 추가
                            let startCoordinate = segments[index].start
                            let endCoordinate = segments[index].end
                            let color = segments[index].color
                            let polyline = MKPolyline(coordinates: [startCoordinate, endCoordinate], count: 2)
                            MapPolyline(coordinates: [startCoordinate, endCoordinate])
                                                   .stroke(color, lineWidth: 6)
                        }
                        MapPolyline(coordinates: mapPathViewModel.coordinates)
                            .stroke(Color.cyan, lineWidth: 2)
                    }
                    .mapControls{
                        VStack{
                            MapUserLocationButton()
                            MapCompass()
                        }
                        
#if !os(watchOS)
                        MapScaleView()
#endif
                    }   .ignoresSafeArea(.all)
                    
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
                    self.minVelocity = mapPathViewModel.velocities.min() ?? 0.0
                    self.maxVelocity = mapPathViewModel.velocities.max() ?? 15.0
                    await computeSegments()
                    isDataLoaded = true
                }
                else {
                    print("self.workout in the mapPathView is nil")
                    isDataLoaded = true
                }
            } else {
             
                self.minVelocity = mapPathViewModel.velocities.min() ?? 0.0
                self.maxVelocity = mapPathViewModel.velocities.max() ?? 15.0
                await computeSegments()
                isDataLoaded = true
                print("mapPathViewModel will not load data in the mapPathViw  workout: \(String(describing: self.workout)) \n    mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout))" )
            }
            
        }
        .ignoresSafeArea()
    }
    
    
    func computeSegments()  async {
        let startIndex = 0
        let endIndexCount = mapPathViewModel.coordinates.count
        let endIndex = endIndexCount - 2
        
        let interval = Int(endIndexCount / 1000) + 1
        let countOfArray  = Int( endIndexCount / interval )
        let endOfArrayIndex = countOfArray  - 2
        
        print("count of array in compute segments: \(countOfArray) endIndex:\(endIndex) interval :\(interval)")
        print("mapPathviewModel.workout in the compute Segment  \(String(describing: mapPathViewModel.workout)) count: \(mapPathViewModel.coordinates.count)")
        
        guard endOfArrayIndex  >= 0 else { return print("endIndexOfArray is less than or equal to 0") }
        
        var segments: [Segment] = Array(repeating: Segment(start: CLLocationCoordinate2D(latitude: 0, longitude: 0), end: CLLocationCoordinate2D(latitude: 0, longitude: 0), color: .clear), count: endOfArrayIndex + 1 )

        let minVelocity = mapPathViewModel.velocities.min() ?? 0.0
        let maxVelocity = mapPathViewModel.velocities.max() ?? 10.0
        let group = DispatchGroup()
        if endIndex  <= 0 {
            return print("endIndex is less than or equal to 0")
        }
        var count = 0
        for index in stride(from: startIndex, to: endIndex  - interval * 3, by: interval)  {
          
            group.enter()

            DispatchQueue.main.async {
                let coordinate = mapPathViewModel.coordinates[index]
                let nextCoordinate = mapPathViewModel.coordinates[index + interval]
              
                let speed = (mapPathViewModel.velocities[index] + mapPathViewModel.velocities[index + interval]) / 2.0
                let color = calculateColor(for: speed, minVelocity: minVelocity, maxVelocity: maxVelocity)
                let segment = Segment(start: coordinate, end: nextCoordinate, color: color)

                    print("index :\(index) count \(count)")
                    segments[count] = segment // 순서 보장을 위해 인덱스 맞춰서 저장
                    count += 1
                    group.leave()
           
            }
            
        }

        group.notify(queue: DispatchQueue.main) {
            self.segments = segments.compactMap { $0 }
         
        }
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
