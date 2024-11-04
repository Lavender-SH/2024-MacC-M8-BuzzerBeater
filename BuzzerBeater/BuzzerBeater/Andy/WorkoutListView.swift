//
//  WorkoutView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/31/24.
//

import SwiftUI

struct WorkoutListView: View {
    @StateObject var viewModel = WorkoutViewModel()
    @State private var isLoading = true

    var body: some View {
        VStack {
            if isLoading {
                // 로딩 중일 때 ProgressView를 표시
                ProgressView("Loading Workouts...")
            } else {
                List(viewModel.workouts) { workout in
                    Text("Start: \(workout.startDate)")
                }
            }
        }
        .task {
            await viewModel.fetchWorkout(appIdentifier: "seastheDay")
            print("viewModel.workouts.count: \(viewModel.workouts.count)")
            isLoading = false
        }
    }
}


struct WorkoutListView_Previews: PreviewProvider {

    static var previews: some View {
        // 미리보기용으로 더미 데이터를 설정합니다.
        WorkoutListView(viewModel:WorkoutViewModel())
         
    }
}
