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
        NavigationView {
            VStack {
                if isLoading {
                    // 로딩 중일 때 ProgressView를 표시
                    ProgressView("Loading Workouts...")
                } else {
                    List(viewModel.workouts , id:\.self ) { workout in
                        NavigationLink(destination: MapPathView(workout: workout)) {
                            
                            // Pass the selected workout to MapView
                            let  textString  = workout.startDate.formatted(.dateTime.year().month(.defaultDigits).day()) + "  " +
                            formattedDuration( workout.duration)
                            Text(textString)
                            
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchWorkout(appIdentifier: "seastheDay")
                print("viewModel.workouts.count: \(viewModel.workouts.count)")
                isLoading = false
            }
            .navigationTitle("Workouts") // Optional: Set the title for the navigation bar
            
        }
    }
    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

}

struct WorkoutListView_Previews: PreviewProvider {

    static var previews: some View {
        // 미리보기용으로 더미 데이터를 설정합니다.
        WorkoutListView(viewModel:WorkoutViewModel())
         
    }
}
