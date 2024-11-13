import SwiftUI
import HealthKit

@main
struct BuzzerBeaterApp: App {
    @StateObject private var viewModel = WorkoutViewModel()  // WorkoutViewModel 인스턴스 생성
    
    init() {
        // 앱 시작 시 LocationManager와 HealthKit 서비스 등을 초기화합니다.
        _ = LocationManager.shared
        _ = WindDetector.shared
        _ = ApparentWind.shared
        _ = SailAngleFind.shared
        _ = SailingDataCollector.shared
        _ = HealthService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            #if os(watchOS)
            ContentView()
                .environmentObject(LocationManager.shared)
                .environmentObject(WindDetector.shared)
                .environmentObject(ApparentWind.shared)
                .environmentObject(SailAngleFind.shared)
                .environmentObject(SailingDataCollector.shared)
                .environmentObject(HealthService.shared)
            
            #elseif os(iOS)
            InfoRow()
            #endif
            //            #elseif os(iOS)
            //
            //            NavigationView {
            //                // iOS에서는 InfoDetail 화면을 기본으로 표시하고 workout 데이터를 전달합니다.
            //                if let latestWorkout = viewModel.workouts.first {
            //                    InfoDetail(workout: latestWorkout)
            //                        .environmentObject(LocationManager.shared)
            //                        .environmentObject(WindDetector.shared)
            //                        .environmentObject(ApparentWind.shared)
            //                        .environmentObject(SailAngleFind.shared)
            //                        .environmentObject(SailingDataCollector.shared)
            //                        .environmentObject(HealthService.shared)
            //                        .onAppear {
            //                            // 앱이 시작될 때 최신 workout 데이터를 가져옵니다.
            //                            Task {
            //                                await viewModel.fetchWorkout(appIdentifier: "seastheDay")
            //                            }
            //                        }
            //                } else {
            //                    Text("No workout data available")
            //                        .font(.title)
            //                        .foregroundColor(.secondary)
            //                        .onAppear {
            //                            // 앱이 시작될 때 최신 workout 데이터를 가져옵니다.
            //                            Task {
            //                                await viewModel.fetchWorkout(appIdentifier: "seastheDay")
            //                            }
            //                        }
            //                }
            //            }
            //            .environmentObject(viewModel)
            //            #endif
            //        }
            //    }
        }
        
    }
}
