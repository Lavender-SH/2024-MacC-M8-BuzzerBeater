//
//  WorkoutView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/31/24.
//

import SwiftUI
struct WorkoutListView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    
    var body: some View {
        VStack {
            List(viewModel.workouts) { workout in
                VStack(alignment: .leading) {
                    Text("Start: \(workout.startDate.formatted())")
                    Text("End: \(workout.endDate.formatted())")
                    Text("Duration: \(workout.duration / 60, specifier: "%.1f") mins")
                    Text("Calories Burned: \(workout.totalEnergyBurned, specifier: "%.1f") kcal")
                    Text("Distance: \(workout.totalDistance / 1000, specifier: "%.2f") km")
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Workouts")
            .onAppear {
                viewModel.loadWorkout(appIdentifier: "seastheday")
            }
        }
    }
}
