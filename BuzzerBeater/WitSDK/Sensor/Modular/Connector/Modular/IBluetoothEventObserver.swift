//
//  蓝牙事件观察者
//
//
//  Created by huangyajun on 2022/8/29.
//

import Foundation

public protocol IBluetoothEventObserver {
    
    // MARK: When a Bluetooth device is found
    func onFoundBle(bluetoothBLE: BluetoothBLE?)
    
    // MARK: When Bluetooth connection is successful
    func onConnected(bluetoothBLE: BluetoothBLE?)
    
    // MARK: When Bluetooth is disconnected
    func onDisconnected(bluetoothBLE: BluetoothBLE?)
    
    // MARK: When connection fails
    func onConnectionFailed(bluetoothBLE: BluetoothBLE?)
}
