import SwiftUI
import HealthKit

@main
struct BuzzerBeaterApp: App {
    @StateObject private var viewModel = WorkoutViewModel()  // WorkoutViewModel 인스턴스 생성
    @State private var isSplashView = true
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // 앱 시작 시 LocationManager와 HealthKit 서비스 등을 초기화합니다.
#if os(watchOS)
        _ = WindDetector.shared
        _ = ApparentWind.shared
        _ = SailAngleFind.shared
        _ = SailingDataCollector.shared
        
        
#elseif os(iOS)
        _ = LocationManager.shared
        _ = HealthService.shared
#endif
    }
    
    var body: some Scene {
        WindowGroup {
                if isSplashView {
                    LaunchScreenView()
                        .ignoresSafeArea()
                        .onAppear {
                            // 3초 후 Splash 화면을 숨김
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isSplashView = false
                            }
                        }
                } else {
#if os(watchOS)
                    ContentView()
                        .environmentObject(LocationManager.shared)
                        .environmentObject(WindDetector.shared)
                        .environmentObject(ApparentWind.shared)
                        .environmentObject(SailAngleFind.shared)
                        .environmentObject(SailingDataCollector.shared)
                        .environmentObject(HealthService.shared)
                        .environmentObject(BleDeviceManager.shared)
#elseif os(iOS)
                    InfoRow()
#endif
                }
            }
        }
    
    
}
struct LaunchScreenView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        // LaunchScreen.storyboard의 Initial View Controller를 로드
        let controller = UIStoryboard(name: "Launch Screen", bundle: nil).instantiateInitialViewController()!
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // 업데이트 로직 필요 없음
    }
}
