//
//  ContentView.swift
//  BleExampleWatch Watch App
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI
import CoreBluetooth
import WitSDKWatch

struct ContentView: View {
    @EnvironmentObject var appContext : AppContext
    
    var body: some View {
        ScrollView {
            
            
            VStack {
                ConnectView()
                    .environmentObject(appContext)
                
                HomeView()
                    .environmentObject(appContext)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
