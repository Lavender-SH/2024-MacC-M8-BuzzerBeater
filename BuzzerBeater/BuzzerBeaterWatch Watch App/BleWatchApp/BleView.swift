//
//  ContentView.swift
//  BleExampleWatch Watch App
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI
import CoreBluetooth
import WitSDKWatchKit

struct BleView: View {
   
    
    var body: some View {
        ScrollView {
            
            
            VStack {
                ConnectView()
                    .environmentObject(BleDeviceManager.shared)
                
                HomeView()
                    .environmentObject(BleDeviceManager.shared)
            }
            .padding()
        }
    }
}

#Preview {
    BleView()
}
