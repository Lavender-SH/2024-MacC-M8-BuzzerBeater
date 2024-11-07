//
//  InfoPage.swift
//  BuzzerBeater
//
//  Created by 박세진 on 11/6/24.
//

import Foundation
import SwiftUI

struct InfoList: View {
    
    var body: some View {
        
        let workouts = Dummy.sampleDummyWorkoutData
        
        var groupedWorkouts: [Date: [DummyWorkoutData]] {
            Dictionary(grouping: workouts) { workout in
                workout.startDate.startOfDay()
            }
        }
        
        NavigationStack {
            List {
                ForEach(groupedWorkouts.keys.sorted(), id: \.self) { date in
                    Section(header: Text(DateFormatter.yearMonthFormatter.string(from: date))
                        .font(.title2)
                        .foregroundColor(.white)
                    ) {
                        ForEach(groupedWorkouts[date] ?? []) { workoutData in
                            NavigationLink {
                                InfoDetail(workoutData: workoutData)
                            } label: {
                                InfoRow(workoutData: workoutData)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    InfoList()
}
