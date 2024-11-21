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
        NavigationView {
            List {
                // NavigationLink로 각각의 뷰를 연결
                NavigationLink(destination: ConnectView().environmentObject(BleDeviceManager.shared)) {
                    Text("Connect View")
                        .font(.headline)
                        .padding()
                }
                NavigationLink(destination: BiasCheckView()) {
                    Text("Bias Check View")
                        .font(.headline)
                        .padding()
                }
            }
            .navigationTitle("Sensor Settings") // 네비게이션 바 제목 설정
        }
    }
}

#Preview {
    BleView()
}
