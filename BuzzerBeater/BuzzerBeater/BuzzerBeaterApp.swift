//
//  BuzzerBeaterApp.swift
//  BuzzerBeater
//
//  Created by Jeho Ahn on 10/7/24.
//

import SwiftUI

@main
struct BuzzerBeaterApp: App {
    init() {
           // 앱 시작 시 LocationManager.shared를 초기화하여 사용 준비를 합니다.
        _ = LocationManager.shared
        _ = WindDetector.shared
        _ = ApparentWind.shared
        _ = SailAngleFind.shared
        _ = SailingDataCollector.shared
        _ = HealthService.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(LocationManager.shared)
                .environmentObject(WindDetector.shared)
                .environmentObject(ApparentWind.shared)
                .environmentObject(SailAngleFind.shared)
                .environmentObject(SailingDataCollector.shared)
                .environmentObject(HealthService.shared)
        }
    }
}
