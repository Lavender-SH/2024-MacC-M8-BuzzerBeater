//
//  InfoRow.swift
//  BuzzerBeater
//
//  Created by 이승현 on 11/13/24.
//

import SwiftUI
import HealthKit

struct InfoRow: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var isLoading = true
    @State private var savedScrollPosition: Int? = nil
    @Namespace private var scrollNamespace
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Workouts...")
                } else {
                    ScrollViewReader { scrollViewProxy in
                        List {
                            ForEach(groupedWorkoutsByMonth(), id: \.key) { month, workouts in
                                Section(header: Text(month)
                                    .font(.headline)
                                    .foregroundColor(.white)) {
                                        ForEach(workouts, id: \.self) { workout in
                                            NavigationLink(
                                                destination: InfoDetail(workout: workout)
                                                    .onDisappear {
                                                        // Save the current scroll position when navigating back
                                                        savedScrollPosition = workout.hashValue
                                                    }
                                            ) {
                                                HStack(spacing: 15) {
                                                    InfoIcon()
                                                        .frame(width: 80, height: 80)
                                                    
                                                    VStack(alignment: .leading) {
                                                        Text("Dinghy Yacht")
                                                            .font(.headline)
                                                        
                                                        let totalDistance = workout.metadata?["TotalDistance"] as? Double ?? 0.0
                                                        Text("\(formattedDistance(totalDistance))")
                                                            .font(.title3)
                                                            .foregroundColor(.cyan)
                                                        
                                                        HStack {
                                                            Spacer()
                                                            Text(DateFormatter.yearMonthDay.string(from: workout.startDate))
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                }
                                            }
                                            .id(workout.hashValue)
                                        }
                                    }
                            }
                        }
                        .refreshable {
                            isLoading = true
                            await viewModel.fetchWorkout(appIdentifier: "seastheDay")
                            isLoading = false
                        }
                        .onAppear {
                            if let position = savedScrollPosition {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    scrollViewProxy.scrollTo(position, anchor: .zero)
                                }
                            }
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
            .task {
                await viewModel.fetchWorkout(appIdentifier: "seastheDay")
                isLoading = false
            }
            .navigationTitle("Navigation record")
            
        }
    }
    
    func formattedDistance(_ distance: Double?) -> String {
        guard let distance = distance else { return "0.00 Km" }
        let kilometer = distance / 1000
        return String(format: "%.2f km", kilometer)
    }
    
    private func groupedWorkoutsByMonth() -> [(key: String, value: [HKWorkout])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM"
        
        let grouped = Dictionary(grouping: viewModel.workouts) { workout in
            formatter.string(from: workout.startDate)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
}
