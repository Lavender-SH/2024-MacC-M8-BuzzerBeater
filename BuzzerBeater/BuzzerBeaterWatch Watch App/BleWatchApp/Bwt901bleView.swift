//
//  Untitled.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/16/24.
//

import SwiftUI
import CoreBluetooth
import simd



struct Bwt901bleView: View{
    
    
    // Bwt901ble instance
    @ObservedObject var device: Bwt901ble
    
    // App context
    @ObservedObject var bleDeviceManager: BleDeviceManager
    
    // MARK: Constructor
    init(_ device: Bwt901ble, _ bleDeviceManager: BleDeviceManager) {
        self.device = device
        self.bleDeviceManager = bleDeviceManager
    }
    
    // MARK: UI page
    var body: some View {
        VStack {
            Toggle(isOn: $device.isOpen) {
                VStack(alignment: .leading) {
                    Text("\(device.name ?? "")")
                        .font(Font.system(size: 12))
                    Text("\(device.mac ?? "")")
                        .font(Font.system(size: 12))
                }
                
            }.onChange(of: device.isOpen) { _, value in
                if value {
                    bleDeviceManager.openDevice(bwt901ble: device)
                }else{
                    bleDeviceManager.closeDevice(bwt901ble: device)
                }
            }
            .font(Font.system(size: 12))
            .padding(10)
        }
    }
}
