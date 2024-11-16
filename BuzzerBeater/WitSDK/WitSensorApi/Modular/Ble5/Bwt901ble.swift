//
//  Bwt901ble sensor object
//  Wit-Example-BLE
//
//  Created by huangyajun on 2022/8/29.
//

import Foundation
import SwiftUI
import CoreBluetooth
import Combine


public class Bwt901ble :Identifiable, ObservableObject{
    
    // Bluetooth Manager    var bluetoothManager: WitBluetoothManager = WitBluetoothManager.instance
    
    // Bluetooth Connection Object
    var bluetoothBLE: BluetoothBLE?
    
    // Device Model
    var deviceModel:DeviceModel?
    
    // Data Record Observer
    var recordObserverList:[IBwt901bleRecordObserver] = [IBwt901bleRecordObserver]()
    
    // Name
    @Published public var name:String?
    
    // Bluetooth Address
    @Published public var mac:String?
    
    // Currently Open or Not
    @Published public var isOpen: Bool = false
    
    // MARK: Constructor Method
    public init(bluetoothBLE: BluetoothBLE?){
        self.bluetoothBLE = bluetoothBLE
        self.name = bluetoothBLE?.peripheral.name
        self.mac = bluetoothBLE?.peripheral.identifier.uuidString
        
        // Device Model
        deviceModel = DeviceModel(
            deviceName: self.mac ?? "",
            protocolResolver: BWT901BLE5_0ProtocolResolver(),
            dataProcessor: BWT901BLE5_0DataProcessor(),
            listenerKey: "61_0"
        )
        
        // Core Connector
        let coreConnector = WitCoreConnector()
        coreConnector.config?.bluetoothBLEOption?.mac = self.mac
        deviceModel?.setCoreConnector(coreConnector: coreConnector)
    }
    
    // MARK: Open Device
    
    @MainActor public func openDevice() throws{
        try deviceModel?.openDevice()
        // Listen for Data
        deviceModel?.registerListenKeyUpdateObserver(obj: self)
    }
    
    // MARK: Close Device
    @MainActor public func closeDevice(){
        deviceModel?.closeDevice()
        //Cancel listening to data
        deviceModel?.removeListenKeyUpdateObserver(obj: self)
    }

    
    // MARK: Get Device Data
    public func getDeviceData(_ key:String) -> String?{
        return deviceModel?.getDeviceData(key)
    }
}

// Control Device
extension Bwt901ble {
    
    // MARK: Calibration
    public func appliedCalibration() throws{
        try sendData([0xFF ,0xAA ,0x01 ,0x01 ,0x00], 10)
    }
    
    // MARK: Start Magnetic Field Calibration
    public func startFieldCalibration() throws{
        try sendData([0xFF ,0xAA ,0x01 ,0x07 ,0x00], 10)
    }
    
    // MARK: End Magnetic Field Calibration
    public func endFieldCalibration() throws{
        try sendData([0xFF ,0xAA ,0x01 ,0x00 ,0x00], 10)
    }
    
    // MARK: Send Protocol Data
    public func sendProtocolData(_ data:[UInt8],_ waitTime:Int64) throws{
        try deviceModel?.sendProtocolData(data, waitTime)
    }
    
  
    // MARK: Send Data
    public func sendData(_ data:[UInt8],_ waitTime:Int64) throws{
       try deviceModel?.sendData(data: data)
        Thread.sleep(forTimeInterval: (Double(waitTime) / 1000))
    }
    
    // MARK: Read Register
    public func readRge(_ data:[UInt8],_ waitTime:Int64,_ callback: @escaping () -> Void) throws{
        try deviceModel?.asyncSendProtocolData(data, waitTime, callback)
    }
    // MARK: Write Register
    
   
    public func writeRge(_ data:[UInt8],_ waitTime:Int64) throws{
        try sendData(data, waitTime)
    }
    
    // MARK: Unlock Register
    public func unlockReg() throws{
        try sendData([0xFF ,0xAA ,0x69 ,0x88 ,0xB5], 10)
    }
    
    // MARK: Save Register
    public func saveReg() throws{
        try sendData([0xFF ,0xAA ,0x00 ,0x00 ,0x00], 10)
    }
    
}

// Operate Data Record Observer
extension Bwt901ble :IListenKeyUpdateObserver{
    
   // MARK: Called here when the key being listened to by the device model is refreshed
    public func onListenKeyUpdate(_ deviceModel: DeviceModel) {
        invokeListenKeyUpdateObserver(self)
    }
   
    // MARK: Call Data Record Observer
    public func invokeListenKeyUpdateObserver(_ bwt901ble:Bwt901ble){
        for item in self.recordObserverList {
            item.onRecord(bwt901ble)
        }
    }
    
    // MARK: Register Data Record Observer
    public func registerListenKeyUpdateObserver(obj:IBwt901bleRecordObserver){
        self.recordObserverList.append(obj)
    }
    
    // MARK: Remove Data Record Observer
    public func removeListenKeyUpdateObserver(obj:IBwt901bleRecordObserver){
        var i = 0
        while i < self.recordObserverList.count {
            let item = self.recordObserverList[i]
            
            if CompareObjectHelper.compareObjectMemoryAddress(item as AnyObject, obj as AnyObject){
                self.recordObserverList.remove(at: i)
            }
            i = i + 1
        }
    }
    
}


enum SensorLabel: String, CaseIterable {
    case left_hand = "left hand"
    case right_hand = "right hand"
    case waist = "waist"
    case left_leg = "left leg"
    case right_leg = "right leg"
}
