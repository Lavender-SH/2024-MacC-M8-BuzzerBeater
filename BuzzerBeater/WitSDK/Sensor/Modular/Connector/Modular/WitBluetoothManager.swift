//
//  蓝牙管理器
//
//  Created by huangyajun on 2022/8/27.
//


import Foundation
import CoreBluetooth


// Used to check if the data was sent successfully!

public class WitBluetoothManager:NSObject {
    
    // Singleton object

   public static let instance = WitBluetoothManager()
    
    // Central object

    var central: CBCentralManager?
    
    //All devices discovered by the central can be saved.
    //When a new device is discovered, it can be sent via notification.
    //The device connection interface can receive the notification and refresh the device list in real-time.

    var deviceList: NSMutableArray?
    
    // Low-energy Bluetooth client
    var bluetoothBLEDist: [String:BluetoothBLE]?
    
    // Set of observers
    var observerList:[IBluetoothEventObserver] = [IBluetoothEventObserver]()
    
    // Scanning in progress

    public var isScaning = false
    
    // MARK: Initializer
    private override init() {
        
        super.init()
        
        self.central = CBCentralManager.init(delegate:self, queue:nil, options:[CBCentralManagerOptionShowPowerAlertKey:false])
        self.deviceList = NSMutableArray()
        self.bluetoothBLEDist = [String:BluetoothBLE]()
        
    }
    
    // MARK: Method to scan for devices with specified search criteria
    public func startScan(_ serviceUUIDS:[CBUUID]?, options:[String: AnyObject]?){
        // Clear all discovered devices

        self.bluetoothBLEDist?.removeAll()
        // Start scanning

        self.central?.scanForPeripherals(withServices: serviceUUIDS, options: options)
        // Mark as scanning in progress
        self.isScaning = true
    }
        public func startScan(){
     
        self.bluetoothBLEDist?.removeAll()
       
        self.central?.scanForPeripherals(withServices: nil, options: nil)
       
        self.isScaning = true
    }
    
   
    public func stopScan() {
        self.isScaning = false
        self.central?.stopScan()
    }
    
  
    func requestConnect(_ model:CBPeripheral) {
        if (model.state != CBPeripheralState.connected) {
            central?.connect(model , options: nil)
        }
    }
    
    // MARK: - Cancel Connection
    func cancelConnect(_ model:CBPeripheral) {
        if (model.state == CBPeripheralState.connected) {
            central?.cancelPeripheralConnection(model)
        }
    }
    
}




extension WitBluetoothManager{
    
    public func registerEventObserver(observer: IBluetoothEventObserver){
        self.observerList.append(observer)
    }
    
    
    public func removeEventObserver(observer: IBluetoothEventObserver){
        var i = 0
    
      
        while i < self.observerList.count {
            let item = self.observerList[i]
            if CompareObjectHelper.compareObjectMemoryAddress(item as AnyObject, observer as AnyObject) {
                self.observerList.remove(at: i)
                continue
            }
            i = i + 1
        }
    }
    
    
   
    public func removeAllObserver(){
        self.observerList.removeAll()
    }
    
    
    // MARK: Notify Bluetooth event observers that a low-energy Bluetooth device has been found

    func notifyObserverOnFoundBle(_ bluetoothBLE: BluetoothBLE?){
        for item in self.observerList{
            item.onFoundBle(bluetoothBLE: bluetoothBLE)
        }
    }
    
    
    // MARK: Notify Bluetooth event observers that the low-energy Bluetooth connection was successful

    func notifyObserverOnConnected(_ bluetoothBLE: BluetoothBLE?){
        for item in self.observerList{
            item.onConnected(bluetoothBLE: bluetoothBLE)
        }
    }
    
    // MARK: Notify Bluetooth event observers that the low-energy Bluetooth connection was disconnected

    func notifyObserverOnDisconnected(_ bluetoothBLE: BluetoothBLE?){
        for item in self.observerList{
            item.onDisconnected(bluetoothBLE: bluetoothBLE)
        }
    }
}



// MARK: -- Central Manager Delegate

extension WitBluetoothManager : CBCentralManagerDelegate{
    
    // MARK: Check if the device running this app supports BLE.
    public func centralManagerDidUpdateState(_ central: CBCentralManager){
        
        if #available(iOS 10.0, *) {
            switch central.state {
                
            case CBManagerState.poweredOn:
                print("Current device Bluetooth status: On")
                
            case CBManagerState.unauthorized:
                print("Current device Bluetooth status: No Bluetooth available")
                
            case CBManagerState.poweredOff:
                print("Current device Bluetooth status: Off")
                
            default:
                print("Current device Bluetooth status: Unknown status")
            }
            //
            
        }
    }
    
//     MARK: Central manager discovered a device. After starting the scan, Bluetooth devices will be discovered, and this delegate method will be called once a device is found.

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //you can determine if it is your company's device based on the device's name here."
        guard peripheral.name != nil , peripheral.name!.contains("WT") else {
            return
        }
        
        var ble:BluetoothBLE?
        
        // Check for duplicates here and add to the device list. Then send a notification.

        if self.bluetoothBLEDist?.keys.contains(peripheral.identifier.uuidString) == false {
            self.bluetoothBLEDist?[peripheral.identifier.uuidString] = BluetoothBLE(peripheral)
        }
        
        // Get the Bluetooth 5.0 connection object
        ble = self.bluetoothBLEDist?[peripheral.identifier.uuidString]
        
        // Notify observers that the device has been found
        notifyObserverOnFoundBle(ble)
        notifyObserverOnFoundBle(ble)
    }
    
    
    // MARK: Successfully connected to the peripheral, start discovering services

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        
        // Start discovering services
        peripheral.discoverServices(nil)
        
        // You can send a notification here to inform the device connection interface that the connection was successful
        let ble = self.bluetoothBLEDist?[peripheral.identifier.uuidString]
        if(ble != nil){
            //ble?.onConnected()
            notifyObserverOnConnected(ble)
        }
    }
    
    // MARK: Failed to connect to the peripheral

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        // 这里可以发通知出去告诉设备连接界面连接失败
        // You can send a notification here to inform the device connection interface that the connection failed

    }
    
    
    // MARK: Connection lost

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "DidDisConnectPeriphernalNotification"), object: nil, userInfo: ["deviceList": self.deviceList as AnyObject])
        
        // You can send a notification here to inform the device connection interface that the connection was lost

        let ble = self.bluetoothBLEDist?[peripheral.identifier.uuidString]
        if(ble != nil){
            notifyObserverOnDisconnected(ble)
        }
    }
    
}
