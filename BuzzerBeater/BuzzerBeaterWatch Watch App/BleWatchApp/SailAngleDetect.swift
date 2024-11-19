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
    
    func startDetect() {
        
        bleDeviceManager.dataPublisher
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] bwt901ble in
                guard let self = self else {
                    print("self is nil in SailAngleDetect")
                    return
                }
                // Process the received data here
                self.angles = bwt901ble
                self.calibateSailAngle()
            }
            .store(in: &cancellables)
    }
    
    func calibateSailAngle(){
        
        let boatHeading = locationManager.boatCourse
        DispatchQueue.main.async {
            self.boatHeading = boatHeading
        }
        let angleZ =  (self.angles.z) + self.biasCompass
        
        let sailAngleFromNorth = fmod (angleZ + 360 , 360)
        DispatchQueue.main.async{
            self.sailAngleFromNorth = sailAngleFromNorth
        }
        var tempSailAngleFromBoatHeading = fmod( sailAngleFromNorth - boatHeading , 360)
        var tempSailAngleFromMast  = 0
        // 왼쪽방향을 넘어서면 오른쪽 방향에서 계산
        if tempSailAngleFromBoatHeading  <  -180 {
             tempSailAngleFromMast  += 360
        }
        if tempSailAngleFromBoatHeading  >=  180 {
             tempSailAngleFromMast  -= 360
        }
        
        if tempSailAngleFromMast < 0 {
            DispatchQueue.main.async {
                self.sailAngleFromMast = -(180 - abs(tempSailAngleFromBoatHeading))
            }
        }
        
        if tempSailAngleFromMast >= 0 {
            DispatchQueue.main.async{
                self.sailAngleFromMast = 180 - abs(tempSailAngleFromBoatHeading)
            }
        }
    }
    
   
    func calibrateBias() {
        let boatHeading = locationManager.boatCourse
        print("Boat Heading: \(boatHeading)")
     
        let deviceHeading = Double(bleDeviceManager.angles.z)
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
            self.boatHeading = boatHeading
            self.biasCompass = bias
            self.deviceHeading = deviceHeadingConverted + bias
        }
        print(bias > 0 ? "Positive Bias: \(bias)" : "Negative Bias: \(bias)")
    }
}


