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
    @EnvironmentObject var mapPathViewModel  : MapPathViewModel
    @Environment(\.presentationMode) var presentationMode
    let workoutManager = WorkoutManager.shared
    var workout: HKWorkout? // or the appropriate type for your workout data
    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    
    @State var  isDataLoaded: Bool = false
    @State var minVelocity: Double = 0.0
    @State var maxVelocity: Double = 10.0
    
    @State var segments: [Segment] = []

    
    var isModal: Bool
    
    init(workout: HKWorkout?, isModal: Bool = false) {
        self.workout = workout
        self.isModal = isModal
    }
    
    var body: some View {
        
        VStack{
            if mapPathViewModel.isSegmentLoaded  ||  mapPathViewModel.isDataLoaded {
                ZStack(alignment: .top) {
                    
                    Map(position: $mapPathViewModel.position, interactionModes: [.zoom] ) {
                      if mapPathViewModel.isDataLoaded  && !mapPathViewModel.isSegmentLoaded {
                          MapPolyline(coordinates: mapPathViewModel.coordinates)
                               .stroke(Color.cyan, lineWidth: 2)
                        }
                    
                        if mapPathViewModel.isSegmentLoaded {
                            ForEach( 0..<mapPathViewModel.segments.count , id:\.self) { index in
                                // 각 segment의 start, end 좌표를 이용해 경로를 지도에 추가
                                let startCoordinate = mapPathViewModel.segments[index].start
                                let endCoordinate = mapPathViewModel.segments[index].end
                                let color = mapPathViewModel.segments[index].color
                                MapPolyline(coordinates: [startCoordinate, endCoordinate])
                                    .stroke(color, lineWidth: 6)
                            }
                        }
                    }
                    .mapControls{
                    
                            MapUserLocationButton()
                            MapCompass()
    
#if !os(watchOS)
                        MapScaleView()
#endif
                    }   .ignoresSafeArea(.all)
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
                    .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if !self.mapPathViewModel.isDataLoaded  && !self.mapPathViewModel.isSegmentLoaded {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
              
                
            }
            
        }
        
        .onAppear{
            Task {
                if mapPathViewModel.workout != self.workout {
                    guard let workout = self.workout else {
                        print("timestamp: \(Date()) workouit is nil in onAppear")
                        return  }
                    print("timestamp:\(Date()) mapPathViewModel will load data in the mapPathView \n self workout: \(String(describing: self.workout?.uuid))    \n mapPathViewModel.workout:\(String(describing: mapPathViewModel.workout?.uuid))" )
                    await mapPathViewModel.loadWorkoutData(workout: workout)
                    
                    await mapPathViewModel.computeSegments()
                    
                    print("timestamp:\(Date()) mapPathViewModel after loadWorkoutData uuid:\(mapPathViewModel.workout?.uuid) isDataLoaded: \(mapPathViewModel.isDataLoaded) segment count :\(mapPathViewModel.segments.count)" )
                }
                else {
                    if !mapPathViewModel.isSegmentLoaded {
                        await mapPathViewModel.computeSegments()
                    }
                    print("timestamp:\(Date()) mapPathViewModel will not load data in the mapPathViw  workout: \(String(describing: self.workout?.uuid))")
                    print("timestamp:\(Date()) segment count :\(mapPathViewModel.segments.count) ")
                }
            }
        }
        .onChange(of: mapPathViewModel.isDataLoaded) { _, newValue in
            Task{
                await mapPathViewModel.computeSegments()
                print("timestamp:\(Date()) isSegmentLoaded changed to \(newValue)")
                print("timestamp:\(Date()) mapPathViewModel.segments.count \(mapPathViewModel.segments.count)")
            }
        }
        .ignoresSafeArea()
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
