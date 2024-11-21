//
//  ResultMap.swift
//  BuzzerBeaterWatch Watch App
//
//  Created by 이승현 on 11/21/24.
//

import SwiftUI
import HealthKit

struct ResultMap: View {
    var workout: HKWorkout // 전달받는 Workout 데이터
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // WatchResultRecord 추가
                WatchResultRecord(workout: workout)
                    .padding(.horizontal)
                
                // MapPathView 추가
                MapPathView(workout: workout, isModal: false)
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
}
