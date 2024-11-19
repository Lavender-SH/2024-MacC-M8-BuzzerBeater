
//
//  Untitled.swift
//  WitSDK
//
//  Created by Giwoo Kim on 11/14/24.
//

import SwiftUI
import CoreBluetooth
import simd

import Combine

class BleDeviceManager: ObservableObject ,IBluetoothEventObserver, IBwt901bleRecordObserver{
    
    static let shared = BleDeviceManager()
    // Get bluetooth manager
    let bluetoothManager = WitBluetoothManager.shared
    
    var dataPublisher = PassthroughSubject<SIMD3<Double >, Never>()
      
     
         
    // Whether to scan the device
    @Published var enableScan = false
    
    // Bluetooth 5.0 sensor object
    @Published var deviceList:[Bwt901ble] = []
    
    
    // Device data to display
    @Published var deviceData: String = "device not connected"
    @Published var angles = SIMD3<Double>(x: 0.0, y: 0.0, z: 0.0)
    @Published var isBlueToothConnected: Bool = false
    @Published var compassBias: Double = 0.0
    
    var cancellables: Set<AnyCancellable> = []
    
    init(){
        // Current scan status
        self.enableScan = self.bluetoothManager.isScaning
        
        // start auto refresh thread
   //     startRefreshThread()
    }
    deinit {
        cancellables.removeAll() // 모든 구독 해제
        print("BleDeviceManager deinitialized")
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
        self.angles  =  getDeviceAngleData(bwt901ble)
        dataPublisher.send(angles)
 
        //Prints to the console, where you can also log the data to your file
        print("onRecrod: \(deviceData)")
    }
    
    
    // MARK: Enable automatic execution thread
    func startRefreshThread(){
        // start a thread
        Timer.publish(every: TimeInterval(0.5), on: .main, in: .common)
            .autoconnect() // Timer가 자동으로 시작하도록 설정
            .sink { [weak self] _ in
                guard let self = self else { 
                    print("self is nil")
                    return
                          }
                if (self.bluetoothManager.isScaning == true && self.deviceList.count > 0){
                    
                    self.refreshView()
                }
             
            } .store(in: &cancellables)
    }
    
    // MARK: Refresh the view thread, which will refresh the sensor data displayed on the page here
    func refreshView (){
        
        // Keep running this thread
        print("bluetoothManager.isScaning in the refreshView \(self.bluetoothManager.isScaning)")
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
    
    
    // MARK: Get the data of the device and concatenate it into a string
    func getDeviceDataToString(_ device:Bwt901ble) -> String {
        var s = ""
        
        s  = "\(s)name:\(device.name ?? "")\n"
        s  = "\(s)mac:\(device.mac ?? "")\n"
        
        s  = "\(s)AngX:\(device.getDeviceData(WitSensorKey.AngleX) ?? "") °\n"
        s  = "\(s)AngY:\(device.getDeviceData(WitSensorKey.AngleY) ?? "") °\n"
        s  = "\(s)AngZ:\(device.getDeviceData(WitSensorKey.AngleZ) ?? "") °\n"
        return s
    }
 

    func getDeviceAngleData(_ device: Bwt901ble) -> SIMD3<Double> {
        let angleX = Double (device.getDeviceData(WitSensorKey.AngleX) ?? "") ?? 0.0
        let angleY = Double(device.getDeviceData(WitSensorKey.AngleY) ?? "") ?? 0.0
        let angleZ = Double (device.getDeviceData(WitSensorKey.AngleZ) ?? "") ?? 0.0
        
        return SIMD3<Double>(x: angleX, y: angleY, z: angleZ)
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




