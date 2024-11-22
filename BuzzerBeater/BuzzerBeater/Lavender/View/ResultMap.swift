//
//  ResultMap.swift
//  BuzzerBeaterWatch Watch App
//
//  Created by 이승현 on 11/21/24.
//

import SwiftUI
import HealthKit

struct ResultMap: View {
    
    let workoutManager = WorkoutManager.shared
    @EnvironmentObject var mapPathViewModel  : MapPathViewModel
    var workout: HKWorkout? // or the appropriate type for your workout data
    let healthStore =  HealthService.shared.healthStore
    let minDegree = 0.000025
    let mapDisplayAreaPadding = 2.0
    @State var  isDataLoaded: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
               
                // WatchResultRecord 추가
                WatchResultRecord(workout: workout)
                    .environmentObject( mapPathViewModel)
                    .padding(.horizontal)
                
                
                // MapPathView 추가
                MapPathView(workout: workout, isModal: false)
                    .environmentObject( mapPathViewModel)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                
            }
            .padding(.top, 50)
        }
        .edgesIgnoringSafeArea(.top)
    }
}

#Preview {
    ResultMap(workout: WatchResultRecord_Previews.createDummyWorkout())
        .environmentObject(MapPathViewModel())
}
