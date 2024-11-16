//
//  低功耗蓝牙客户端
//  
//  Created by huangyajun on 2022/8/27.
//

import Foundation
import CoreBluetooth

public class BluetoothBLE:NSObject{
    
    // Service UUID
    var uuidService: String?

    // UUID for sending characteristics
    var uuidSend: String?

    // UUID for reading characteristics
    var uuidRead: String?

    // Bluetooth manager
    @MainActor
    var bluetoothManager: WitBluetoothManager = WitBluetoothManager.instance

    // Currently connected device
    public var peripheral: CBPeripheral!

    // Characteristic for sending data (Save the required characteristic after connecting to the device for convenience)
    var sendCharacteristic: CBCharacteristic?

    // Data reception interface
    var dataReceivedList: [IDataReceivedObserver] = [IDataReceivedObserver]()

    // Device address
    public var mac: String?

   
    
    init(_ peripheral:CBPeripheral){
        super.init()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.mac = peripheral.identifier.uuidString
    }
    
    // MARK: 连接蓝牙
    @MainActor func connect(){
        bluetoothManager.requestConnect(self.peripheral)
    }
    
    // MARK: 当连接成功时会回掉这个方法
    func onConnected(){
        
    }
    
    // MARK: 关闭连接
    @MainActor func disconnect(){
        bluetoothManager.cancelConnect(self.peripheral)
    }
    
    // MARK: Send Data
    func sendData(_ data: Data) {

        // Do not send if not connected

        if (peripheral.state != .connected) {
            return
        }
        
        // Do not send if there is no send characteristic
        if (sendCharacteristic == nil) {
            return
        }
        
        peripheral.writeValue(data , for: sendCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    // MARK: Send Data
    func sendData (_ data:[UInt8]){
        sendData(Data(data))
    }
}

// Trigger data reception events
extension BluetoothBLE : IDataObserved{
    
    // MARK: Invoke objects to receive data
    func invokeDataRecevied(data:[UInt8]){
        for item in dataReceivedList {
            item.onDataReceived(data: data)
        }
    }
    
    // MARK: Register objects to receive data
    func registerDataRecevied(obj:IDataReceivedObserver){
        self.dataReceivedList.append(obj)
    }
    
    // MARK: Remove objects from receiving data
    func removeDataRecevied(obj:IDataReceivedObserver){
        var i = 0
        while i < self.dataReceivedList.count {
            let item = self.dataReceivedList[i]
            
            if CompareObjectHelper.compareObjectMemoryAddress(item as AnyObject, obj as AnyObject){
                self.dataReceivedList.remove(at: i)
            }
            i = i + 1
        }
    }
}


// Delegate for discovering services

extension BluetoothBLE : CBPeripheralDelegate {
    
 // MARK: - Match corresponding service UUID

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        
        if error != nil {
            return
        }
        
        // Iterate through all services

        for service in peripheral.services! {
            // If it is the specified service UUID, start searching for characteristics
            // print("SERVICE UUID ID:\(service.uuid.uuidString.uppercased())")
            // If it is Low Energy Single Mode Bluetooth

            if service.uuid.uuidString.uppercased() == BLEUUID.UUID_SERVICE.uppercased() {
                self.uuidService = BLEUUID.UUID_SERVICE
                self.uuidRead = BLEUUID.UUID_READ
                self.uuidSend = BLEUUID.UUID_SEND
                peripheral.discoverCharacteristics(nil, for: service )
            }
            
            // If it is Dual Mode Bluetooth

            if service.uuid.uuidString == DualUUID.UUID_SERVICE {
                self.uuidService = DualUUID.UUID_SERVICE
                self.uuidRead = DualUUID.UUID_READ
                self.uuidSend = DualUUID.UUID_SEND
                peripheral.discoverCharacteristics(nil, for: service )
            }
        }
        
    }
    
  // MARK: - Characteristics under the service
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        
        if (error != nil){
            return
        }
        
        for  characteristic in service.characteristics! {
            print("Find the device characteristic value UUID：\(characteristic.uuid.description)")
            switch characteristic.uuid.description.uppercased() {
                case self.uuidRead:
                //Subscribe to the characteristic value, and after a successful subscription,
                //all subsequent value changes will be automatically notified
                peripheral.setNotifyValue(true, for: characteristic)
                break
            case "******":
                // Read the characteristic value in the read-only area, which can only be read once
                peripheral.readValue(for:characteristic)
                break
            case self.uuidSend:
                // Obtain the write characteristic value
                sendCharacteristic = characteristic
                break
            default:
                print("Scan for other characteristics.")
                break
            }
            
        }
        
    }
    
    //MARK: - The subscription status of the characteristic has changed."
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?){
        
        guard error == nil  else {
            return
        }
        
    }
    
    // MARK: - Get data received from the peripheral
    // Note: All characteristic values, whether read or notify, are received here

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)-> (){
        
        if(error != nil){
            return
        }
        
        switch characteristic.uuid.uuidString.uppercased() {
            
        case self.uuidRead:
           // Print the timestamp of the received data
            let dformatter = DateFormatter()
            dformatter.dateFormat = "yyyyMMdd-HH.mm.ss"
            let current = Date()
            let dateString = dformatter.string(from: current) + ".\((CLongLong(round(current.timeIntervalSince1970*1000)) % 1000))"
//            print(dateString)
//             print("Received data from the device \(String(describing: characteristic.value?.dataToHex()))")
            let bytes:[UInt8]? = characteristic.value?.dataToBytes()
            if bytes != nil {
                // Call the object to receive data"
                invokeDataRecevied(data: bytes ?? [UInt8]())
            }
            break
        default:
            print("Received other characteristic data: \(characteristic.uuid.uuidString)")
            break
        }
    }
    
    
    
    //MARK:  Check if the data written from the central to the peripheral was successful
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error != nil){
            print(" Failed to send data! Error information: : \(String(describing: error))")
        }
    }
    
}

// // Bluetooth Low Energy UUID

class BLEUUID{
    
    // Service uuid
    static let UUID_SERVICE:String = "0000ffe5-0000-1000-8000-00805f9a34fb".uppercased()
    
    // Send characteristic value uuid
    static let UUID_SEND:String = "0000ffe9-0000-1000-8000-00805f9a34fb".uppercased()
    
    //  Read characteristic value uuid
    static let UUID_READ:String = "0000ffe4-0000-1000-8000-00805f9a34fb".uppercased()
}


//  Dual-mode Bluetooth UUID
class DualUUID{
    
    // Service UUID
    static let UUID_SERVICE:String = "49535343-fe7d-4ae5-8fa9-9fafd205e455".uppercased()
    
    //Send characteristic UUID
    static let UUID_SEND:String = "49535343-8841-43f4-a8d4-ecbe34729bb3".uppercased()
    
    // Read characteristic UUID

    static let UUID_READ:String = "49535343-1e4d-4bd9-ba61-23c647249616".uppercased()
}


