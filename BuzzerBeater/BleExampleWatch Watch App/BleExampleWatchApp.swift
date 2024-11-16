//
//  BleExampleWatchApp.swift
//  BleExampleWatch Watch App
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI

@main
struct BleExampleWatch_Watch_AppApp: App {
    @StateObject var appContext: AppContext = AppContext()
     
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appContext)
        }
    }
}
