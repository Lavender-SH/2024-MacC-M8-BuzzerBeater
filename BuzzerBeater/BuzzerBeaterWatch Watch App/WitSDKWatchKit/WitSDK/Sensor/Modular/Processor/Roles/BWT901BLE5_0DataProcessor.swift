//
// Bluetooth 5.0 Data Processor

//
//  Created by huangyajun on 2022/9/1.
//

import Foundation


class BWT901BLE5_0DataProcessor : IDataProcessor {
    
    // Control the thread for automatic data reading
    var readDataThreadRuning:Bool = false
    
    // Device model
    var deviceModel:DeviceModel?
    
    // When the sensor is turned on
    func onOpen(deviceModel: DeviceModel) {
        self.deviceModel = deviceModel
        // Start the data reading thread

        let thread = Thread(target: self,
                            selector: #selector(readDataThread),
                            object: nil)
        readDataThreadRuning = true
        thread.start()
    }
    
    // Automatic data reading thread

    @objc func readDataThread(){
        
        var count:Int = 0;
        while (readDataThreadRuning) {
            do {
                
                let magType:String? = deviceModel?.getDeviceData("72");//Magnetic field type

                if (StringUtils.IsNullOrEmpty(magType)) {
                    // Read the 72 magnetic field type register, which will be used later when parsing the magnetic field

                    try sendProtocolData(data: [0xff, 0xaa, 0x27, 0x72, 0x00], waitTime: 0.5);
                }
                
                let reg2e:String? = deviceModel?.getDeviceData("2E");// Version number
                let reg2f:String? = deviceModel?.getDeviceData("2F");// // Version number

                if (StringUtils.IsNullOrEmpty(reg2e) || StringUtils.IsNullOrEmpty(reg2f)) {
                    // Read version number

                    try sendProtocolData(data: [0xff,0xaa, 0x27, 0x2E, 0x00], waitTime: 0.5);
                }
                
                try sendProtocolData(data: [0xff, 0xaa, 0x27, 0x3a, 0x00], waitTime: 0.5);// Magnetic field

                try sendProtocolData(data: [0xff, 0xaa, 0x27, 0x51, 0x00], waitTime: 0.5);// Quaternion

                // No need to read data at such a fast rate

                count = count + 1
                if (count % 50 == 0 || count < 5) {
                    try sendProtocolData(data: [ 0xff, 0xaa, 0x27, 0x64, 0x00], waitTime: 0.5);// Battery level

                    try sendProtocolData(data: [ 0xff, 0xaa, 0x27, 0x40, 0x00], waitTime: 0.5);// Temperature
//                    WitCoreConnect coreConnect = deviceModel.getCoreConnect();
//                    BluetoothBLEOption bluetoothBLEOption = coreConnect.getConfig().getBluetoothBLEOption();
//                    deviceModel.setDeviceData(WitSensorKey.SignalValue, WitBluetoothManager.getRssi(bluetoothBLEOption.getMac()) + "");
                }
            } catch {
                print("BWT901BLECL5_0DataProcessor:Automatic data reading exception");
            }
        }
        
    }

    func sendProtocolData(data: [UInt8], waitTime:TimeInterval) throws{
        try deviceModel?.sendProtocolData(data: data);
        Thread.sleep(forTimeInterval: waitTime)
    }
    
    // When the sensor is turned off

    func onClose() {
        readDataThreadRuning = false
    }
    
    // When the sensor is updated

    func onUpdate(deviceModel:DeviceModel) {
        
        // Acceleration
        let regAx:String? = deviceModel.getDeviceData("61_0");
        let regAy:String? = deviceModel.getDeviceData("61_1");
        let regAz:String? = deviceModel.getDeviceData("61_2");
        // Angular velocity

        let regWx:String? = deviceModel.getDeviceData("61_3");
        let regWy:String? = deviceModel.getDeviceData("61_4");
        let regWz:String? = deviceModel.getDeviceData("61_5");
        // Angle

        let regAngleX:String? = deviceModel.getDeviceData("61_6");
        let regAngleY:String? = deviceModel.getDeviceData("61_7");
        let regAngleZ:String? = deviceModel.getDeviceData("61_8");
        
        // Quaternion

        let regQ1:String? = deviceModel.getDeviceData("51");
        let regQ2:String? = deviceModel.getDeviceData("52");
        let regQ3:String? = deviceModel.getDeviceData("53");
        let regQ4:String? = deviceModel.getDeviceData("54");
        // Temperature and battery level

        let regTemperature:String? = deviceModel.getDeviceData("40");
        let regPower:String? = deviceModel.getDeviceData("64");
        
        
        // Version number

        let reg2e:String? = deviceModel.getDeviceData("2E");// 版本号
        let reg2f:String? = deviceModel.getDeviceData("2F");// 版本号
        
   
        // If there is a version number

        if (reg2e != nil &&
            reg2f != nil) {
            let reg2eValue:Int16 = Int16((reg2e as NSString?)?.intValue ?? 0)
            let reg2fValue:Int16 = Int16((reg2f as NSString?)?.intValue ?? 0)
            
            let sum = Int32(reg2fValue) << 16 | Int32(reg2eValue)
            let tempVersion:UInt32 = UInt32(bitPattern: sum)
            var sbinary:String =  String(tempVersion, radix: 2)
            sbinary = StringUtils.padLeft(sbinary, 32, "0")
            if (sbinary.first == "1")// New version number

            {
                var tempNewVS:String = String(UInt32(StringUtils.subString(sbinary, (4 - 3), (14 + 3)), radix: 2) ?? 0)
                tempNewVS = tempNewVS + "." + String(UInt32(StringUtils.subString(sbinary, 18, 6), radix: 2) ?? 0)
                tempNewVS = tempNewVS + "." + String(UInt32(StringUtils.subString(sbinary, 24, 8), radix: 2) ?? 0)
                deviceModel.setDeviceData(WitSensorKey.VersionNumber, tempNewVS)
            } else {
                deviceModel.setDeviceData(WitSensorKey.VersionNumber, "\(reg2eValue)")
            }
        }
        
        // Acceleration calculation

        if (!StringUtils.IsNullOrEmpty(regAx)) {
            deviceModel.setDeviceData(WitSensorKey.AccX, String(format:"%.3f", Double.parseDouble(regAx) / 32768 * 16, 3));
        }
        if (!StringUtils.IsNullOrEmpty(regAy)) {
            deviceModel.setDeviceData(WitSensorKey.AccY, String(format:"%.3f", Double.parseDouble(regAy) / 32768 * 16, 3));
        }
        if (!StringUtils.IsNullOrEmpty(regAz)) {
            deviceModel.setDeviceData(WitSensorKey.AccZ, String(format:"%.3f", Double.parseDouble(regAz) / 32768 * 16, 3));
        }
        
        // Angular velocity calculation

        if (!StringUtils.IsNullOrEmpty(regWx)) {
            deviceModel.setDeviceData(WitSensorKey.GyroX, String(format:"%.3f", Double.parseDouble(regWx) / 32768 * 2000, 3));
        }
        if (!StringUtils.IsNullOrEmpty(regWy)) {
            deviceModel.setDeviceData(WitSensorKey.GyroY, String(format:"%.3f", Double.parseDouble(regWy) / 32768 * 2000, 3));
        }
        if (!StringUtils.IsNullOrEmpty(regWz)) {
            deviceModel.setDeviceData(WitSensorKey.GyroZ, String(format:"%.3f", Double.parseDouble(regWz) / 32768 * 2000, 3));
        }
        
        // Angle

        if (!StringUtils.IsNullOrEmpty(regAngleX)) {
            deviceModel.setDeviceData(WitSensorKey.AngleX, String(format:"%.3f", Double.parseDouble(regAngleX) / 32768 * 180, 3));
        }
        if (!StringUtils.IsNullOrEmpty(regAngleY)) {
            deviceModel.setDeviceData(WitSensorKey.AngleY, String(format:"%.3f", Double.parseDouble(regAngleY) / 32768 * 180, 3));
        }
        if (!StringUtils.IsNullOrEmpty(regAngleZ)) {
            let anZ:String = String(format:"%.3f", Double.parseDouble(regAngleZ) / 32768 * 180, 3)
            deviceModel.setDeviceData(WitSensorKey.AngleZ, anZ);
        }
        // Magnetic field

        let regHX:String? = deviceModel.getDeviceData("3A");
        let regHY:String? = deviceModel.getDeviceData("3B");
        let regHZ:String? = deviceModel.getDeviceData("3C");
        // Magnetic field type

        let magType:String? = deviceModel.getDeviceData("72");
        if (!StringUtils.IsNullOrEmpty(regHX) &&
            !StringUtils.IsNullOrEmpty(regHY) &&
            !StringUtils.IsNullOrEmpty(regHZ) &&
            !StringUtils.IsNullOrEmpty(magType)
        ) {
            let type:Int16 = Int16(magType ?? "0", radix: 10) ?? 0
            // Calculate the data and save it to the device data

            deviceModel.setDeviceData(WitSensorKey.MagX, String(DipSensorMagHelper.GetMagToUt(type, Double.parseDouble(regHX))));
            deviceModel.setDeviceData(WitSensorKey.MagY, String(DipSensorMagHelper.GetMagToUt(type, Double.parseDouble(regHY))));
            deviceModel.setDeviceData(WitSensorKey.MagZ, String(DipSensorMagHelper.GetMagToUt(type, Double.parseDouble(regHZ))));
        }
        
        // Temperature

        if (!StringUtils.IsNullOrEmpty(regTemperature)) {
            deviceModel.setDeviceData(WitSensorKey.Temperature, String(format: "%.2f", Double.parseDouble(regTemperature) / 100, 2));
        }
        
        // Battery level

        if (!StringUtils.IsNullOrEmpty(regPower)) {
            
            let regPowerValue:Int = Int(regPower ?? "0", radix: 10) ?? 0
            let eqPercent:Int = getEqPercent(Float(Float(regPowerValue) / 100.0));
            deviceModel.setDeviceData(WitSensorKey.ElectricQuantityPercentage,  String(eqPercent));
            
            
            // Calculate battery percentage

            // if (regPowerValue >= 830) {
            //     deviceModel.setDeviceData(WitSensorKey.ElectricQuantityPercentage, "100");
            // } else if (regPowerValue >= 750 && regPowerValue < 830) {
            //     deviceModel.setDeviceData(WitSensorKey.ElectricQuantityPercentage, "75");
            // } else if (regPowerValue >= 715 && regPowerValue < 750) {
            //     deviceModel.setDeviceData(WitSensorKey.ElectricQuantityPercentage, "50");
            // } else if (regPowerValue >= 675 && regPowerValue < 715) {
            //     deviceModel.setDeviceData(WitSensorKey.ElectricQuantityPercentage, "25");
            // } else if (regPowerValue <= 675) {
            //     deviceModel.setDeviceData(WitSensorKey.ElectricQuantityPercentage, "0");
            // }
            
            // Raw battery value

            deviceModel.setDeviceData(WitSensorKey.ElectricQuantity, String(regPowerValue) );
        }
        
        // Quaternion

        if (!StringUtils.IsNullOrEmpty(regQ1)) {
            deviceModel.setDeviceData(WitSensorKey.Q0, String(format:"%.5f", Double.parseDouble(regQ1) / 32768.0));
        }
        if (!StringUtils.IsNullOrEmpty(regQ2)) {
            deviceModel.setDeviceData(WitSensorKey.Q1, String(format:"%.5f", Double.parseDouble(regQ2) / 32768.0));
        }
        if (!StringUtils.IsNullOrEmpty(regQ3)) {
            deviceModel.setDeviceData(WitSensorKey.Q2, String(format:"%.5f", Double.parseDouble(regQ3) / 32768.0));
        }
        if (!StringUtils.IsNullOrEmpty(regQ4)) {
            deviceModel.setDeviceData(WitSensorKey.Q3, String(format:"%.5f", Double.parseDouble(regQ4) / 32768.0));
        }
        
    }
    
    // Get the current value

    func getEqPercent(_ eq:Float) -> Int {
        var p:Int = 0;
        if(eq >= 3.96){
            p = 100
        }
        else if(eq >= 3.93 && eq < 3.96){
            p = 90
        }
        else if(eq >= 3.87 && eq < 3.93){
            p = 75
        }
        else if(eq >= 3.82 && eq < 3.87){
            p = 60
        }
        else if(eq >= 3.79 && eq < 3.82){
            p = 50
        }
        else if(eq >= 3.77 && eq < 3.79){
            p = 40
        }
        else if(eq >= 3.73 && eq < 3.77){
            p = 30
        }
        else if(eq >= 3.70 && eq < 3.73){
            p = 20
        }
        else if(eq >= 3.68 && eq < 3.70){
            p = 15
        }
        else if(eq >= 3.50 && eq < 3.68){
            p = 10
        }
        else if(eq >= 3.40 && eq < 3.50){
            p = 5
        }
        else if(eq < 3.40){
            p = 0
        }
        return p;
    }
    
    // Match percentage

    func Interp(_ a:Float,_ x:[Float],_ y:[Float]) -> Float {
        var v:Float = 0;
        let L:Int = x.count;
        if (a < x[0]) { v = y[0]}
        else if (a > x[L - 1]) {v = y[L - 1]}
        else {
            var i:Int = 0
            while (i < y.count - 1) {
                if (a > x[i + 1]) { i = i+1; continue; }
                v = y[i] + (a - x[i]) / (x[i + 1] - x[i]) * (y[i + 1] - y[i]);
                break;
            }
        }
        return v;
    }
    
    func ReadMagType( deviceModel:DeviceModel) {
        // Read the 72 magnetic field type register, which will be used later when parsing the magnetic field

        //deviceModel.sendProtocolData(new byte[]{(byte) 0xff, (byte) 0xaa, 0x27, 0x72, 0x00});
    }
}


// Extend double

extension Double {
    static func parseDouble(_ str:String) -> Double{
        return ((str as NSString).doubleValue)
    }
    
    static func parseDouble(_ str:String?) -> Double{
        return ((str as NSString?)?.doubleValue ?? 0)
    }
}

