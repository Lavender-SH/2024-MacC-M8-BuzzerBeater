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
                calibrateBias()
            } .font(Font.system (size:16))
            .padding()
        }
    }

    func calibrateBias() {
        guard let boatHeading = locationManager.heading?.magneticHeading else {
            print("No Heading information")
            return
        }

        print("Boat Heading: \(boatHeading)")
        let deviceHeading = Double(viewModel.angles.z)
        print("Device Heading: \(deviceHeading)")

        // Convert deviceHeading
        let deviceHeadingConverted = deviceHeading < 0 ? -Double(deviceHeading) : 360 - Double(deviceHeading)
        
        var bias = (boatHeading - 180) - deviceHeadingConverted
        
        if bias > 180 {
            bias -= 360
        }
        if bias < -180 {
            bias += 360
        }
        DispatchQueue.main.async{
            self.deviceHeading = deviceHeadingConverted
            self.boatHeading = boatHeading
            self.biasCompass = bias
        }
        print(bias > 0 ? "Positive Bias: \(bias)" : "Negative Bias: \(bias)")
    }
}
