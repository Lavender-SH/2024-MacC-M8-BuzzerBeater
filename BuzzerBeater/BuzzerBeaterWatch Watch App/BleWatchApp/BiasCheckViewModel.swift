//
//  BiasCheckViewModel.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/20/24.
//  화면버튼을  combine으로 해봤는데..괜찮을지 모르겠네..
import SwiftUI
import Combine
class BiasCheckViewModel: ObservableObject {
    let bleDeviceManager = BleDeviceManager.shared
    let locationManager = LocationManager.shared
    let sailAngleDetect = SailAngleDetect.shared
    var cancellables: Set<AnyCancellable> = []
    @Published var endSailDetectButtonEnabled: Bool = false
    @Published var startSailDetectButtonEnabled: Bool = false
    init() {
        startSailDetectButtonCheck()
        endSailDetectButtonCheck()
    }
    
    deinit{
        cancellables.removeAll()
    }
    func startSailDetectButtonCheck(){
        Publishers.CombineLatest(bleDeviceManager.canEnableButton, sailAngleDetect.$isSailAngleDetect)
            .map { canEnableButton, isSailAngleDetect in
                return canEnableButton && !isSailAngleDetect // Enable button if both are true
            }
            .sink { [weak self] canEnable in
                self?.startSailDetectButtonEnabled = canEnable // Update the button state based on the conditions
            }
            .store(in: &cancellables) // Stor
        
    }
    
    func endSailDetectButtonCheck() {
        Publishers.CombineLatest(bleDeviceManager.canEnableButton, sailAngleDetect.$isSailAngleDetect)
            .map { canEnableButton, isSailAngleDetect in
                print("canEnableButton: \(canEnableButton), isSailAngleDetect: \(isSailAngleDetect)")
                // canEnableButton이 false인 경우 isSailAngleDetect을 false로 강제
                if !canEnableButton {
                    return (false, false) // Return both canEnable and modified isSailAngleDetect
                }
                return (canEnableButton, isSailAngleDetect)
            }
            .sink { [weak self] canEnable, updatedIsSailAngleDetect in
                self?.endSailDetectButtonEnabled = canEnable && updatedIsSailAngleDetect
                self?.sailAngleDetect.isSailAngleDetect = updatedIsSailAngleDetect
            }
            .store(in: &cancellables)
    }

}
