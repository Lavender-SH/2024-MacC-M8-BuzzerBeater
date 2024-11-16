//
//  HomeView.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/16/24.
//
import SwiftUI
import CoreBluetooth
import simd
import WitSDKWatchKit

// MARK: Home view start
// **********************************************************
struct HomeView: View {
    
    
    // App the context
    @EnvironmentObject var viewModel: BleDeviceManager
    
  // MARK: UI page
    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .center){
                HStack {
                    Text(" Control device")
                        .font(Font.system(size: 10))
                }
                HStack{
                    VStack{
                        Button("Acc cali") {
                            viewModel.appliedCalibration()
                        }.padding(5)
                        Button("Start mag"){
                            viewModel.startFieldCalibration()
                        }.padding(5)
                        Button("Stop mag"){
                            viewModel.endFieldCalibration()
                        }.padding(5)
                    }.font(Font.system(size: 10))
                    VStack{
                        Button("Read03reg"){
                            viewModel.readReg03()
                        }.padding(10)
                        Button("Set50hzrate"){
                            viewModel.setBackRate50hz()
                        }.padding(10)
                        Button("Set10hzrate"){
                            viewModel.setBackRate10hz()
                        }.padding(10)
                    }.font(Font.system(size: 10))
                }
                
                HStack {
                    Text("Device data")
                        .font(Font.system(size: 10))
                }
                Text(String(format: "%.f", self.viewModel.angles.x))
                Text(String(format: "%.f", self.viewModel.angles.y))
                Text(String(format: "%.f", self.viewModel.angles.z))
            }.font(Font.system(size: 12))
        }.navigationBarHidden(true)
    }
}


struct Home_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}


