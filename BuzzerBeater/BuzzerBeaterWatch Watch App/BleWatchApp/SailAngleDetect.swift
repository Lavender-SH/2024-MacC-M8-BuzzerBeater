//
//  SailAngleDetect.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/19/24.
//

import SwiftUI
import Combine
import simd

class SailAngleDetect : ObservableObject{
 
    static let shared = SailAngleDetect()
    
    let locationManager =  LocationManager.shared
    let bleDeviceManager = BleDeviceManager.shared
    
    @Published var isSailAngleDetect: Bool = false
    
    @Published var sailAngle: Double = 0
    @Published var angles: SIMD3<Double> = SIMD3<Double>(x: 0, y: 0, z: 0)
    @Published var boatHeading : Double = 0
    @Published var deviceHeading : Double = 0
    @Published var biasCompass : Double  = 0
    
    @Published var sailAngleFromNorth : Double = 0
    @Published var sailAngleFromMast : Double = 0
  
    var cancellables : Set<AnyCancellable> = []

    init(){
        startDetect()
    }
    
    
    deinit {
        
        cancellables.removeAll()
        
    }
    func startDetect() {
        
        bleDeviceManager.dataPublisher
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] angles in
                guard let self = self else {
                    print("self is nil in SailAngleDetect")
                    return
                }
                // Process the received data here
                if self.isSailAngleDetect {
                    self.angles = angles
                    self.calibateSailAngle()
                }
            }
            .store(in: &cancellables)
        
        
        
    }
    
    func calibateSailAngle(){
        
        let boatHeading = locationManager.boatCourse
        DispatchQueue.main.async {
            self.boatHeading = boatHeading
            print("calib:biasCompas \(self.biasCompass)")
            print("calib: boatHeading \(self.boatHeading)")
            
        }
        let deviceHeading = Double(self.angles.z)
    
        // Convert deviceHeading north Clockwise
        let deviceHeadingConverted = deviceHeading < 0 ? -Double(deviceHeading) : 360 - Double(deviceHeading)
        
        
        DispatchQueue.main.async{
            self.deviceHeading = deviceHeadingConverted + self.biasCompass
        }
  
        let sailAngleFromNorth = fmod (self.deviceHeading + 360 , 360)
        
        DispatchQueue.main.async{
            self.sailAngleFromNorth = sailAngleFromNorth
            print("calib:sailAngleFromNorth \(self.sailAngleFromNorth)")
        }
        var tempSailAngleFromBoatHeading = fmod( sailAngleFromNorth - boatHeading  + 360 , 360)
        
        DispatchQueue.main.async {
            self.sailAngleFromMast = (180 - tempSailAngleFromBoatHeading)
            print("calib:sailAngleFromMast \(self.sailAngleFromMast)")
        }
    }
    
   
    func calibrateBias() {
        let boatHeading = locationManager.boatCourse
      
        let deviceHeading = Double(bleDeviceManager.angles.z)
    
        // Convert deviceHeading north Clockwise
        let deviceHeadingConverted = deviceHeading < 0 ? -Double(deviceHeading) : 360 - Double(deviceHeading)
        
        var bias = (boatHeading - 180) - deviceHeadingConverted
        print("calib 1 bias: \(bias)")
        
        //0 <= bias <= 180  or -180 <= bias < 0
        if bias > 180 {
            bias -= 360
        }
        if bias < -180 {
            bias += 360
        }
        print("calib 2 bias:\(bias)")
       DispatchQueue.main.async{
            self.boatHeading = boatHeading
            self.biasCompass = bias
            self.deviceHeading = deviceHeadingConverted + bias
        }
        print(String(format: "angles (%.0f, %.0f, %.0f)",
                     bleDeviceManager.angles.x,
                     bleDeviceManager.angles.y,
                     bleDeviceManager.angles.z))
        print(String(format: "calib boat Heading: %.0f", self.boatHeading))
        print(String(format: "calib device Heading before adj: %.0f", deviceHeadingConverted))
        print(String(format: "calib device Heading: %.0f", self.deviceHeading))
        print(String(format: "calib: Bias: %.0f", self.biasCompass))
    }
}


