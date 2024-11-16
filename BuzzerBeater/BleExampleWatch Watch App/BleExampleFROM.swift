
//
//  Untitled.swift
//  WitSDK
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI
import CoreBluetooth
import WitSDKWatch
import simd


class AppContext: ObservableObject ,IBluetoothEventObserver, IBwt901bleRecordObserver{
    
    static let shared = AppContext()
    // Get bluetooth manager
    let bluetoothManager:WitBluetoothManager = WitBluetoothManager.instance 
    
   
    // Whether to scan the device
    @Published var enableScan = false
  
    // Bluetooth 5.0 sensor object
    @Published var deviceList:[Bwt901ble] = []
    
 
    // Device data to display
    @Published var deviceData: String = "device not connected"
    @Published var angles = SIMD3<Float>(x: 0.0, y: 0, z: 0)
    @Published var isBlueToothConnected: Bool = false
    @Published var compassBias: Double = 0.0
    
    init(){
       
        // Current scan status
        self.enableScan = self.bluetoothManager.isScaning
      
        // start auto refresh thread
        startRefreshThread()
    }
    
    
    // MARK: Start scanning for devices
    @MainActor func scanDevices() {
        print("Start scanning devices...")
        
        // Remove all devices, here all devices are turned off and removed from the list
        removeAllDevice()
     
        // Registering a Bluetooth event observer
        self.bluetoothManager.registerEventObserver(observer: self)
     
        // Turn on bluetooth scanning
        self.bluetoothManager.startScan()
    }
    
   
    // MARK: This method is called if a Bluetooth Low Energy sensor is found
    func onFoundBle(bluetoothBLE: BluetoothBLE?) {
        if isNotFound(bluetoothBLE) {
            print("\(String(describing: bluetoothBLE?.peripheral.name)) found a bluetooth device \(bluetoothBLE?.mac ?? "")")
            self.deviceList.append(Bwt901ble(bluetoothBLE: bluetoothBLE))
            print("self.deviceList.count:\(self.deviceList.count) \(self.deviceList)")
        }
    }

    // Judging that the device has not been found
    func isNotFound(_ bluetoothBLE: BluetoothBLE?) -> Bool{
        guard let bluetoothBLE = bluetoothBLE else {
            print("bluetooth ble is nil")
            return false
        }
        for device in deviceList {
            if device.mac == bluetoothBLE.mac {
                return false
            }
        }
        return true
    }
    
   
    // MARK: You will be notified here when the connection is successful
    func onConnected(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name)) found a bluetooth device \(bluetoothBLE?.mac ?? "")")
    }
    
  
    // MARK: Notifies you here when the connection fails
    func onConnectionFailed(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name)) found a bluetooth device \(bluetoothBLE?.mac ?? "")")
    }
    
    // MARK: You will be notified here when the connection is lost
    func onDisconnected(bluetoothBLE: BluetoothBLE?) {
        print("\(String(describing: bluetoothBLE?.peripheral.name)) found a bluetooth device \(bluetoothBLE?.mac ?? "")")
    }
    
   
    // MARK: Stop scanning for devices
    func stopScan(){
     
        self.bluetoothManager.removeEventObserver(observer: self)
      
        self.bluetoothManager.stopScan()
    }
    
   
    // MARK: Turn on the device
    @MainActor func openDevice(bwt901ble: Bwt901ble?){
        print("MARK: Turn on the device")
        
        do {
            try bwt901ble?.openDevice()
          
            // Monitor data
            bwt901ble?.registerListenKeyUpdateObserver(obj: self)
            isBlueToothConnected = true
        }
        catch{
            print("Failed to open device")
        }
    }
 
    // MARK: Remove all devices
    @MainActor func removeAllDevice(){
        print("device List in the removeAllDevice: \(deviceList)")
        
        isBlueToothConnected = false
        for item in deviceList {
            print("device in the removeAllDevice: \(item)")
            closeDevice(bwt901ble: item)
        }
        print("remove all device")
        deviceList.removeAll()
    }
    
   
    // MARK: Turn off the device
    @MainActor func closeDevice(bwt901ble: Bwt901ble?){
        print("Turn off the device")
        isBlueToothConnected = false
        bwt901ble?.closeDevice()
      
    }
    
    
    // MARK: You will be notified here when data from the sensor needs to be recorded
    func onRecord(_ bwt901ble: Bwt901ble) {
       
        let deviceData =  getDeviceDataToString(bwt901ble)
        
        //Prints to the console, where you can also log the data to your file
        print("onRecrod: \(deviceData)")
    }
    
   
    // MARK: Enable automatic execution thread
    func startRefreshThread(){
        // start a thread
        let thread = Thread(target: self,
                            selector: #selector(refreshView),
                            object: nil)
        thread.start()
    }
    
    // MARK: Refresh the view thread, which will refresh the sensor data displayed on the page here
    @objc func refreshView (){
       
        // Keep running this thread
        while true {
            // Refresh 5 times per second
            Thread.sleep(forTimeInterval: 1 / 5)
           
            // Temporarily save sensor data
            var tmpDeviceData:String = ""
          
            // Print the data of each device
            print("deviceList in the  refreshView  \(deviceList)")
            for device in deviceList {
                if (device.isOpen){
              
                    // Get the data of the device and concatenate it into a string
                    let deviceData =  getDeviceDataToString(device)
                    tmpDeviceData = "\(tmpDeviceData)n\(deviceData)"
                    print("tempDeviceData \(tmpDeviceData)")
                }
            }
            // Refresh ui
            DispatchQueue.main.async {
                self.deviceData = tmpDeviceData
            }
            
        }
    }
    
   
    // MARK: Get the data of the device and concatenate it into a string
    func getDeviceDataToString(_ device:Bwt901ble) -> String {
        var s = ""
        
        s  = "\(s)name:\(device.name ?? "")\n"
        s  = "\(s)mac:\(device.mac ?? "")\n"
     
        s  = "\(s)AngX:\(device.getDeviceData(WitSensorKey.AngleX) ?? "") °\n"
        s  = "\(s)AngY:\(device.getDeviceData(WitSensorKey.AngleY) ?? "") °\n"
        s  = "\(s)AngZ:\(device.getDeviceData(WitSensorKey.AngleZ) ?? "") °\n"

        getDeviceAngleData(device)
        return s
    }
    
    func getDeviceAngleData(_ device:Bwt901ble) {
        var s = ""
        s  = "\(s)name:\(device.name ?? "")\n"
        s  = "\(s)mac:\(device.mac ?? "")\n"
        DispatchQueue.main.async {
            self.angles.x = Float(device.getDeviceData(WitSensorKey.AngleX) ?? "") ?? 0.0
            self.angles.y = Float(device.getDeviceData(WitSensorKey.AngleY) ?? "") ?? 0.0
            self.angles.z = Float(device.getDeviceData(WitSensorKey.AngleZ) ?? "") ?? 0.0
        }
        
    }
    
    
    
    // MARK: Addition calibration
    func appliedCalibration(){
        for device in deviceList {
            
            do {
              
                // Unlock register
                try device.unlockReg()
              
                // Addition calibration
                try device.appliedCalibration()
               
                // save
                try device.saveReg()
                
            }catch{
                print(" Set failed")
            }
        }
    }
    
   
    // MARK: Start magnetic field calibration
    func startFieldCalibration(){
        for device in deviceList {
            do {
         
                // Unlock register
                try device.unlockReg()

                // Start magnetic field calibration
                try device.startFieldCalibration()

                // save
                try device.saveReg()
            }catch{
                print("Set failed")
            }
        }
    }
    

    // MARK: End magnetic field calibration
    func endFieldCalibration(){
        for device in deviceList {
            do {

                // Unlock register
                try device.unlockReg()
       
                // End magnetic field calibration
                try device.endFieldCalibration()

                // save
                try device.saveReg()
            }catch{
                print("Set failed")
            }
        }
    }
    

    // MARK: Read the 03 register
    func readReg03(){
        for device in deviceList {
            do {
                
                // Read the 03 register and wait for 200ms. If it is not read out, you can extend the reading time or read it several times
                try device.readRge([0xff ,0xaa, 0x27, 0x03, 0x00], 200, {
                    let reg03value = device.getDeviceData("03")
                  
                    // Output the result to the console
                    print("\(String(describing: device.mac)) reg03value: \(String(describing: reg03value))")
                })
            }catch{
                print(" Set failed")
            }
        }
    }
    
   
    // MARK: Set 50hz postback
    func setBackRate50hz(){
        for device in deviceList {
            do {
               
                // unlock register
                try device.unlockReg()
          
                // Set 50hz postback and wait 10ms
                try device.writeRge([0xff ,0xaa, 0x03, 0x08, 0x00], 10)
               
                // save
                try device.saveReg()
            }catch{
                print("设置失败 Set failed")
            }
        }
    }
    
   
    // MARK: Set 10hz postback
    func setBackRate10hz(){
        for device in deviceList {
            do {
                
                // unlock register
                try device.unlockReg()
              
                // Set 10hz postback and wait 10ms
                try device.writeRge([0xff ,0xaa, 0x03, 0x06, 0x00], 100)
               
                // save
                try device.saveReg()
            }catch{
                print(" Set failed")
            }
        }
    }
}

// **********************************************************

// MARK: Home view start
// **********************************************************
struct HomeView: View {
    
    
    // App the context
    @EnvironmentObject var viewModel:AppContext
    
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


// **********************************************************

// MARK: Start with the view
// **********************************************************
struct ConnectView: View {
    
    // App context
    @EnvironmentObject var viewModel: AppContext
    
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

// **********************************************************

// MARK: View showing Bluetooth 5.0 sensor
// **********************************************************
struct Bwt901bleView: View{
    
   
    // Bwt901ble instance
    @ObservedObject var device: Bwt901ble
    
    // App context
    @ObservedObject var viewModel: AppContext
    
    // MARK: Constructor
    init(_ device: Bwt901ble, _ viewModel: AppContext) {
        self.device = device
        self.viewModel = viewModel
    }
    
    // MARK: UI page
    var body: some View {
        VStack {
            Toggle(isOn: $device.isOpen) {
                VStack(alignment: .leading) {
                    Text("\(device.name ?? "")")
                        .font(Font.system(size: 12))
                    Text("\(device.mac ?? "")")
                        .font(Font.system(size: 12))
                }

            }.onChange(of: device.isOpen) { _, value in
                if value {
                    viewModel.openDevice(bwt901ble: device)
                }else{
                    viewModel.closeDevice(bwt901ble: device)
                }
            }
            .font(Font.system(size: 12))
            .padding(10)
        }
    }
}
