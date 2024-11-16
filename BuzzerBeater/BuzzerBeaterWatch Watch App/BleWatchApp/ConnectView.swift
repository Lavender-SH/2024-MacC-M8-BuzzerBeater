//
//  Untitled.swift
//  BuzzerBeater
//
//  Created by Giwoo Kim on 11/16/24.
//

import SwiftUI
import CoreBluetooth
import simd
import WitSDKWatchKit

// **********************************************************

// MARK: Start with the view
// **********************************************************
struct ConnectView: View {
    
    // App context
    @EnvironmentObject var viewModel: BleDeviceManager  
    
    // MARK: Constructor
  
    // MARK: UI page
    var body: some View {
        ZStack(alignment: .leading) {
            VStack{
                Toggle(isOn: $viewModel.enableScan){
                    Text("Turn on device scanning :")
                }.onChange(of: viewModel.enableScan) {_, value in
                    if value {
                        viewModel.scanDevices()
                    } else {
                        viewModel.stopScan()
                    }
                }.padding(5)
                
                ScrollViewReader { proxy in
                    
                    ForEach (self.viewModel.deviceList) { device in
                        Bwt901bleView(device, viewModel)
                        
                    }
                    .onAppear {
                        print(" list: \(self.viewModel.deviceList) count:  \(self.viewModel.deviceList.count)")
                    }
                    
                }
                
            }.font(Font.system(size: 12))
        }
    }
}


struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
          
    }
}


