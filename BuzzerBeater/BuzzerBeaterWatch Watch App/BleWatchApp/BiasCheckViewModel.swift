//
//  BiasCheckViewModel.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/20/24.
//
import SwiftUI
import Combine
class BiasCheckViewModel: ObservableObject {
    let bleDeviceManager = BleDeviceManager.shared
    let locationManager = LocationManager.shared
    let sailAngleDetect = SailAngleDetect.shared
    var cancellables: Set<AnyCancellable> = []
    @Published var isButtonEnabled: Bool = false
    init() {
        startButtonCheck()
    }
    
    deinit{
        cancellables.removeAll()
    }
    func startButtonCheck(){
        Publishers.CombineLatest(bleDeviceManager.canEnableButton, sailAngleDetect.$isSailAngleDetect)
            .map { canEnableButton, isSailAngleDetect in
                return canEnableButton && !isSailAngleDetect // Enable button if both are true
            }
            .sink { [weak self] canEnable in
                self?.isButtonEnabled = canEnable // Update the button state based on the conditions
            }
            .store(in: &cancellables) // Stor
        
}
    
}
