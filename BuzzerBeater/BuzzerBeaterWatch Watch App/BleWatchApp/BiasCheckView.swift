//
//  BiasCheckView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/17/24.
//

import SwiftUI
import Combine

struct BiasCheckView: View {
    @EnvironmentObject var bleDeviceManager : BleDeviceManager
    @StateObject  var biasCheckViewModel = BiasCheckViewModel()

    let locationManager = LocationManager.shared
    @EnvironmentObject var sailAngleDetect : SailAngleDetect
   
    @State private var biasCompass: Double = 0
    @State private var boatHeading: Double = 0
    @State private var deviceHeading : Double = 0
    @State private var showToast = false
    
    var body: some View {
        
        VStack {
            //            Text("Bias Check") .font(Font.system (size:16))
            //            Text("Align the Boat Heading in your watch and Sail in line.").font(Font.system (size:16))
            //
            //            Text("Bias: \(sailAngleDetect.biasCompass, specifier: "%.f")") .font(Font.system (size:16))
            //            Text("Boat Heading : \(sailAngleDetect.boatHeading, specifier: "%.f")") .font(Font.system (size:16))
            //            Text("Sail Heading : \(sailAngleDetect.deviceHeading, specifier: "%.f")") .font(Font.system (size:16))
            HStack {
                Text(String(format: "( %.f ,", self.bleDeviceManager.angles.x))
                Text(String(format: "%.f ," , self.bleDeviceManager.angles.y))
                Text(String(format: "%.f )", self.bleDeviceManager.angles.z))
            }
            
            HStack {
                ZStack {
                    VStack {
                        Button("Calibrate") {
                            SailAngleDetect.shared.calibrateBias()
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showToast = true // 부드럽게 나타남
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.7)) {
                                    showToast = false // 부드럽게 사라짐
                                }
                            }
                        }
                        .font(Font.system(size: 11))
                        .padding(5)
                    }
                    // 토스트 메시지
                    if showToast {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill") // 체크 아이콘
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.bottom, 20) // 화면 하단 여백
                            .opacity(showToast ? 1 : 0) // 투명도 애니메이션
                        }
                    }
                }
                Button(sailAngleDetect.isSailAngleDetect ? "Hide Sail" : "Show Sail") {
                    sailAngleDetect.isSailAngleDetect.toggle() // 상태를 토글
                }
                .font(Font.system(size: 12))
                .disabled(sailAngleDetect.isSailAngleDetect
                          ? !biasCheckViewModel.endSailDetectButtonEnabled
                          : !biasCheckViewModel.startSailDetectButtonEnabled)
                .padding(5)
            }
        }
    }
}
