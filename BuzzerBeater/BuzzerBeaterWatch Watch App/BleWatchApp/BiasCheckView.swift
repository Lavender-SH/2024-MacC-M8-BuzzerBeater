//
//  BiasCheckView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/17/24.
//

import SwiftUI

struct BiasCheckView: View {
    @ObservedObject var viewModel = BleDeviceManager.shared
    let locationManager = LocationManager.shared
    @State private var biasCompass: Double = 0
    @State private var boatHeading: Double = 0
    @State private var deviceHeading : Double = 0
    
    var body: some View {
        VStack {
            Text("Bias Check") .font(Font.system (size:16))
            Text("Align the Boat Heading in your watch and Sail in line.").font(Font.system (size:16))
            
            Text("Bias: \(biasCompass, specifier: "%.2f")") .font(Font.system (size:16))
            Text("Boat Heading : \(boatHeading, specifier: "%.f")") .font(Font.system (size:16))
                .padding()
            Text("Sail Heading : \(deviceHeading, specifier: "%.f")") .font(Font.system (size:16))
            Button("Calibrate Bias") {
                SailAngleDetect.shared.calibrateBias()
            } .font(Font.system (size:16))
            .padding()
            Button("Show SailAngle ") {
                SailAngleDetect.shared.isSailAngleDetect = true
            } .font(Font.system (size:16))
            .padding()
            
            Button("Hide SailAngle ") {
                SailAngleDetect.shared.isSailAngleDetect = false
            } .font(Font.system (size:16))
            .padding()
        }
    }
}
