//
//  设备模型
//
//  Created by huangyajun on 2022/8/27.
//

import Foundation
import SwiftUI

public class DeviceModel {
    
    // MARK: 设备名称
    var deviceName:String?
    
    // MARK: 监听的key值
    var listenerKey:String?
    
    // MARK: 连接器
    var coreConnect:WitCoreConnector?
    
    // MARK: 数据处理器
    var dataProcessor:IDataProcessor
    
    // MARK: 协议解析器
    var protocolResolver:IProtocolResolver
    
    // MARK: 是否打开的
    var isOpen:Bool = false
    
    // MARK: 是否关闭中
    var closing:Bool = false
    
    // MARK: 设备数据
    var deviceData:[String:String] = [String:String]()
    
    // 修改设备数据锁
    let deviceDataLock = NSLock()
    
    // 发送数据锁
    let sendDataLock = NSLock()

    // 是否等待返回
    var bolWaitReturn = false
    
    // 返回的数据
    var returnDataBuffer:[UInt8] = [UInt8]()
    
    // 接收数据锁
    // let returnDataBufferLock = NSLock()
    
    // 监听的key刷新观察者
    var listenKeyUpdateObserverList:[IListenKeyUpdateObserver] = [IListenKeyUpdateObserver]()
    
    // key刷新事件观察者
    var keyUpdateObserverList:[IKeyUpdateObserver] = [IKeyUpdateObserver]()
    
    // MARK: 构造方法
    init(deviceName:String,protocolResolver:IProtocolResolver,dataProcessor:IDataProcessor, listenerKey:String){
        self.deviceName = deviceName
        self.protocolResolver = protocolResolver
        self.dataProcessor = dataProcessor
        self.listenerKey = listenerKey
    }
}

// 打开设备和关闭设操作
extension DeviceModel{
    
    // MARK: Set connection object
    func setCoreConnector(coreConnector:WitCoreConnector){
        self.coreConnect = coreConnector
    }
    
    // MARK: Open device
    @MainActor func openDevice() throws{
        
        if (coreConnect != nil) {
            // Open connector
            try coreConnect?.open()
            coreConnect?.registerDataRecevied(obj: self)
            
            // Call the data processing open method
            dataProcessor.onOpen(deviceModel: self)
            
        }else{
            throw DeviceModelError.openError(msaage:"Failed to open device, no connection object" )
        }
        
    }
    
    // MARK: Reopen
    @MainActor func reOpen() throws{
        self.closeDevice()
        try self.openDevice()
    }
    
    // MARK: Close device
    @MainActor func closeDevice(){
        // Call the data processing close method
        dataProcessor.onClose()
        // Close connector
        coreConnect?.close()
        coreConnect?.removeDataRecevied(obj: self)
    }
}

// Device data operations
extension DeviceModel{
    
    // MARK: Set data
    func setDeviceData(_ key:String,_ value:String){
        
        deviceDataLock.lock()
        deviceData[key] = value
        deviceDataLock.unlock()
        
        // Trigger the listener's key value
        if key == listenerKey {
            // Call the data processor to update data
            dataProcessor.onUpdate(deviceModel: self)
            // Call the key to update the observer
            invokeListenKeyUpdateObserver(self)
        }
        
        // Call the listener key to update the observer
        invokeKeyUpdateObserver(self, key, value)
    }
    
    // MARK: Get device data
    func getDeviceData(_ key:String) -> String?{
        
        var value:String? = nil
        
        deviceDataLock.lock()
        // Return nil if not contained
        if deviceData.keys.contains(key) {
            value = deviceData[key]
        }
        
        deviceDataLock.unlock()
        
        return value
    }
}


// When data is received
extension DeviceModel:IDataReceivedObserver{
    // MARK: When receiving data from the device
    func onDataReceived(data: [UInt8]) {
        
        // If waiting for a return
        if (bolWaitReturn) {
            //returnDataBufferLock.lock()
            returnDataBuffer.append(contentsOf: data)
            //returnDataBufferLock.unlock()
        }
        
        // MARK: Call protocol handler
        protocolResolver.passiveReceiveData(data: data, deviceModel: self)
    }
}


// 发送数据
extension DeviceModel {
    
    // MARK: 发送数据，需要返回数据
    func sendData(data: [UInt8], callback:(_ rtnData:[UInt8]) -> Void, waitTime:Int64) throws {
        // 开启线程锁
        sendDataLock.lock()
        bolWaitReturn = true
        returnDataBuffer.removeAll()
        do{
            // 发送读取命令
            try sendData(data: data)
            // 等待返回
            Thread.sleep(forTimeInterval: Double(waitTime) / 1000.0)
            
            bolWaitReturn = false
            // 调用回掉方法
            let copyList = returnDataBuffer
            callback(copyList)
        } catch {
            bolWaitReturn = false
        }
        // 取消线程锁
        sendDataLock.unlock()
    }
    
    // MARK: 发送数据, 不需要返回数据
    func sendData(data: [UInt8]) throws{
        coreConnect?.sendData(data)
    }
    
    // MARK: 发送协议数据 (同步)
    func sendProtocolData(_ data: [UInt8],_ waitTime:Int64) throws{
        try self.protocolResolver.sendData(sendData: data, deviceModel: self, waitTime: waitTime)
    }

    // MARK: 发送协议数据 (同步)
    func sendProtocolData(data: [UInt8]) throws{
        try sendData(data: data)
    }
    
    // MARK: Send protocol data (asynchronous)

    func asyncSendProtocolData(_ data: [UInt8],_ waitTime:Int64,_ callback:@escaping () -> Void) throws{
        // Start a thread

        let thread = Thread(block: {
            do{
                try self.sendProtocolData(data, waitTime)
                callback()
            }catch{
                
            }
        })
        thread.start()
    }
}


// Event handling

extension DeviceModel {
    
    // MARK: Invoke key update observer

    func invokeKeyUpdateObserver(_ deviceModel:DeviceModel, _ key:String,_ value:String){
        for item in self.keyUpdateObserverList {
            item.onKeyUpdate(deviceModel, key, value)
        }
    }
    
    // MARK: Register key update observer

    func registerKeyUpdateObserver(_ obj:IKeyUpdateObserver){
        self.keyUpdateObserverList.append(obj)
    }
    
    // MARK: Remove key update observer
    func removeKeyUpdateObserver(_ obj:IKeyUpdateObserver){
        var i = 0
        while i < self.keyUpdateObserverList.count {
            let item = self.keyUpdateObserverList[i]
            
            if CompareObjectHelper.compareObjectMemoryAddress(item as AnyObject, obj as AnyObject){
                self.keyUpdateObserverList.remove(at: i)
            }
            i = i + 1
        }
    }
    
    // MARK: Invoke listener for key update observer

    func invokeListenKeyUpdateObserver(_ deviceModel:DeviceModel){
        for item in self.listenKeyUpdateObserverList {
            item.onListenKeyUpdate(deviceModel)
        }
    }
    
    // MARK: Register listener for key update observer

    func registerListenKeyUpdateObserver(obj:IListenKeyUpdateObserver){
        self.listenKeyUpdateObserverList.append(obj)
    }
    
    // MARK: Remove listener for key update observer

    func removeListenKeyUpdateObserver(obj:IListenKeyUpdateObserver){
        var i = 0
        while i < self.listenKeyUpdateObserverList.count {
            let item = self.listenKeyUpdateObserverList[i]
            
            if CompareObjectHelper.compareObjectMemoryAddress(item as AnyObject, obj as AnyObject){
                self.listenKeyUpdateObserverList.remove(at: i)
            }
            i = i + 1
        }
    }
}
