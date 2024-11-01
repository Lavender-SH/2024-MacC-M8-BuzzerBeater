//
//  WorkoutView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 10/31/24.
//

import SwiftUI

struct WorkoutListView: View {
    @StateObject  var viewModel = WorkoutViewModel()
    @State private var isLoading = true
    let shared = WorkoutViewModel.shared
    
    var body: some View {
        VStack {
            Text("Text: Workouts")
          
            List(viewModel.workouts) { workout in
              
                        Text("Start: \(workout.startDate)")
                
                
            }
            
        }.task {
            await viewModel.fetchWorkout(appIdentifier: "seastheDay")
            print("shared workouts: \(viewModel.workouts)")
            print("viewModel.workouts.count: \(viewModel.workouts.count)")
            isLoading = false
           
        }
        .navigationTitle("Title: Workouts")
        
    }
}

struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        // 미리보기용으로 더미 데이터를 설정합니다.
        WorkoutListView()
         
    }
}
