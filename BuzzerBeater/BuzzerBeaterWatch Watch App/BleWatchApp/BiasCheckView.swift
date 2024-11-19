//
//  BiasCheckView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/17/24.
//

import SwiftUI

struct BiasCheckView: View {
    @EnvironmentObject var bleDeviceManager : BleDeviceManager
    let locationManager = LocationManager.shared
    let sailAngleDetect = SailAngleDetect.shared
    @State private var biasCompass: Double = 0
    @State private var boatHeading: Double = 0
    @State private var deviceHeading : Double = 0
    
    var body: some View {
        
        VStack {
            Text("Bias Check") .font(Font.system (size:16))
            Text("Align the Boat Heading in your watch and Sail in line.").font(Font.system (size:16))
            
            Text("Bias: \(sailAngleDetect.biasCompass, specifier: "%.2f")") .font(Font.system (size:16))
            Text("Boat Heading : \(sailAngleDetect.boatHeading, specifier: "%.f")") .font(Font.system (size:16))
                .padding()
            Text("Sail Heading : \(sailAngleDetect.deviceHeading, specifier: "%.f")") .font(Font.system (size:16))
            
            
            
            Button("Calibrate Bias") {
                SailAngleDetect.shared.calibrateBias()
            } .font(Font.system (size:16))
                .padding(5)
            Button("Show SailAngle ") {
                sailAngleDetect.isSailAngleDetect = true
            } .font(Font.system (size:16))
            .padding(5)
            
            Button("Hide SailAngle ") {
                sailAngleDetect.isSailAngleDetect = false
            } .font(Font.system (size:16))
            .padding(5)
        }
    }
}
