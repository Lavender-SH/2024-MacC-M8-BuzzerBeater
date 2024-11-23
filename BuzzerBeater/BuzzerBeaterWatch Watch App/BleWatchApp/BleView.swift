//
//  ContentView.swift
//  BleExampleWatch Watch App
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI
import CoreBluetooth


struct BleView: View {
    
    var body: some View {
        VStack {
            ConnectView()
                .environmentObject(BleDeviceManager.shared)
//            HomeView()
//                .environmentObject(BleDeviceManager.shared)
            
            BiasCheckView()
        }
        .padding()
    }
}

#Preview {
    BleView()
}
