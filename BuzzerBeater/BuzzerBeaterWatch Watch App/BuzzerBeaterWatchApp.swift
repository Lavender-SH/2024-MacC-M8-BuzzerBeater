//
//  BuzzerBeaterWatchApp.swift
//  BuzzerBeaterWatch Watch App
//
//  Created by 이승현 on 10/19/24.
//

import SwiftUI

@main

struct BuzzerBeaterWatch_Watch_AppApp: App {
    init() {
           // 앱 시작 시 LocationManager.shared를 초기화하여 사용 준비를 합니다.
        _ = LocationManager.shared
        _ = WindDetector.shared
        _ = ApparentWind.shared
        _ = SailAngleFind.shared
        _ = SailingDataCollector.shared
        _ = HealthService.shared
        _ = BleDeviceManager.shared
        _ = WorkoutManager.shared
        _ = SailAngleDetect.shared
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView().ignoresSafeArea(.all)
                .environmentObject(LocationManager.shared)
                .environmentObject(WindDetector.shared)
                .environmentObject(ApparentWind.shared)
                .environmentObject(SailAngleFind.shared)
                .environmentObject(SailingDataCollector.shared)
                .environmentObject(HealthService.shared)
                .environmentObject(BleDeviceManager.shared)
                .environmentObject(WorkoutManager.shared)
                .environmentObject(SailAngleDetect.shared)
        }
    }
}
