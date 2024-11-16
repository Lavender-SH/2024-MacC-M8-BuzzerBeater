//
//  Core Connector.
//
//  Created by huangyajun on 2022/8/31.
//
import Foundation

class WitCoreConnector {
    
    // Bluetooth Connection
    var bleClient: BluetoothBLE?

    // Connection Parameters
    var config: ConnectConfig? = ConnectConfig()

    // Connection Type
    var connectType: ConnectType? = .BLE

    // Connection Status
    var connectStatus: ConnectStatus? = .Closed

    // Data Reception Interface
    var dataReceivedList: [IDataReceivedObserver] = [IDataReceivedObserver]()

}


// Open and Close Connection
extension WitCoreConnector{
    
    // MARK: Open
    
    @MainActor func open() throws{
       
    
        try checkConfig()
        
        // If it is a connection to Low Energy Bluetooth
        if (connectType == ConnectType.BLE) {
            
            // Get the Bluetooth Client
            bleClient = WitBluetoothManager.instance.bluetoothBLEDist?[config?.bluetoothBLEOption?.mac ?? ""]
            
            if (bleClient == nil) {
                throw CoreConnectError.ConnectError(message: " Nonexistent Bluetooth Device")
            }
            
            // Connect to Bluetooth
            bleClient?.connect()
            bleClient?.registerDataRecevied(obj: self)
        }
        
        // Mark as Opened
        self.connectStatus = .Opened
    }
    
    // MARK: Check Parameters
    func checkConfig() throws{
        // If it is connecting to Low Energy Bluetooth (BLE)
        if (connectType == ConnectType.BLE) {
            if (config?.bluetoothBLEOption == nil) {
                throw CoreConnectError.ConnectConfigError(message: "")
            }
            
            if (config?.bluetoothBLEOption?.mac == nil) {
                throw CoreConnectError.ConnectConfigError(message: "")
            }
        }
    }
    
    // MARK: Close Connection
    @MainActor func close(){
        // Mark as Closed
        self.connectStatus = .Closed
        
        // Disconnect Bluetooth 5.0 connection
        bleClient?.disconnect()
        bleClient?.removeDataRecevied(obj: self)
    }
    
    // MARK: Is it Opened?
    func isOpen() -> Bool {
        return self.connectStatus == .Opened
    }
}

// Send Data
extension WitCoreConnector {
    
    // MARK: Send Data
    func sendData (_ data:[UInt8]){
        // If it is connecting to Low Energy Bluetooth (BLE)
        if (connectType == ConnectType.BLE) {
            bleClient?.sendData(data)
        }
    }
    
}

// Receive Data
extension WitCoreConnector :IDataReceivedObserver{
    
    // When data is received
    func onDataReceived(data: [UInt8]) {
        invokeDataRecevied(data: data)
    }
    
}

// Trigger Data Reception Event
extension WitCoreConnector : IDataObserved{
    
    // MARK: Invoke objects that need to receive data
    func invokeDataRecevied(data:[UInt8]){
        for item in dataReceivedList {
            item.onDataReceived(data: data)
        }
    }
    
    // MARK: Register Data Reception Object
    func registerDataRecevied(obj:IDataReceivedObserver){
        self.dataReceivedList.append(obj)
    }
    
    // MARK: Remove Data Reception Object
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


// 连接类型
enum ConnectType{
    
    // 低功耗蓝牙
    case BLE
    
}

// Connection Type
enum ConnectStatus{
    
    // Opened
    case Opened
    
    // Closed
    case Closed
    
}



// Connection Parameters
class ConnectConfig {
    
    // Low Energy Bluetooth Connection Options
    var bluetoothBLEOption:BluetoothBLEOption? = BluetoothBLEOption()
    
}


// Bluetooth 5.0 Connection Parameters
class BluetoothBLEOption {
    
    // Bluetooth Address
    var mac:String?
    
}


// 连接错误
enum CoreConnectError: Error{
    
    // 连接参数错误
    case ConnectConfigError(message:String)
    
    // 连接错误
    case ConnectError(message:String)
    
}


// IDataReceivedObserver
protocol IDataReceivedObserver
{
    // When data is received
    func onDataReceived(data:[UInt8])
    
}

//  translates to Data Receiving Subject
protocol IDataObserved {
    
    // MARK: Call the object that needs to receive data
    func invokeDataRecevied(data:[UInt8])
    
    // MARK: Register data receiving object

    func registerDataRecevied(obj:IDataReceivedObserver)
    
    // MARK: Remove data receiving object

    func removeDataRecevied(obj:IDataReceivedObserver)
    
}

// Data echo interface

protocol SendDataInterface
{
    func onSendData(data:[UInt8])
}
