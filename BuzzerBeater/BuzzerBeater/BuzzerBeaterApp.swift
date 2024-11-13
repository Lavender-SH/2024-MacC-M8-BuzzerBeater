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
        }
    }
}
