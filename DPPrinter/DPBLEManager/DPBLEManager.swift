//
//  DPBLEManager.swift
//  DPPrinter
//
//  Created by developeng on 2023/6/7.
//

import UIKit
import CoreBluetooth

enum DPOptionStage {
    case connectStart // 蓝牙连接开始
    case connectSuccess // 蓝牙连接成功
    case connectFail // 蓝牙连接失败
    case seekService // 搜索服务
    case seekCharacteristic // 搜索特性
    case seekDescriptors // 搜索描述
}

class DPBLEManager: NSObject{
    
    // 发现外设回调
    var centralState:((_ central:CBCentralManager)->Void)?
    
    // 发现外设回调
    var didDiscoverPeripheral:((_ central:CBCentralManager,_ peripheral:CBPeripheral,_ advertisementData:Dictionary<String, Any>,_ rssi:NSNumber)->Void)?
    // 连接外设状态回调
    var connectStageBlock:((_ stage:DPOptionStage,_ peripheral:CBPeripheral,_ service:CBService?,_ character:CBCharacteristic?,_ error:Error?)->Void)?
 
    /**
     * 每次发送的最大数据长度，因为部分型号的蓝牙打印机一次写入数据过长，会导致打印乱码。
     * iOS 9之后，会调用系统的API来获取特性能写入的最大数据长度。
     * 但是iOS 9之前需要自己测试然后设置一个合适的值。默认值是146。
     * 所以，如果你打印乱码，你考虑将该值设置小一点再试试。
     */
    private var limitLength:Int = 90
    /// 是否连接成功后停止扫描蓝牙设备
    var stopScanAfterConnected:Bool = true
    
    
    /// 中心管理器
    private var centralManager:CBCentralManager!
    /// 当前连接的外设
    private var printerPeripheral: CBPeripheral!
  
    private var serviceUUIDs: [CBUUID]? = nil
    private var characteristicUUIDs: [CBUUID]? = nil
    /// 可写入数据的特性
    private var character: CBCharacteristic!
    
    /// 写入次数
    private var writeCount:Int = 0
    /// 返回次数
    private var responseCount:Int = 0
    
    /// 采用工厂模式-可通过不同的key初始化多个实例
    private static var instances: [String: DPBLEManager] = [:]
    static func shared(_ key: String? = nil) -> DPBLEManager {
        var classKey:String = "default"
        if let key = key {
            classKey = key
        }
         if let instance = instances[classKey] {
             return instance
         } else {
             let newInstance = DPBLEManager()
             instances[classKey] = newInstance
             return newInstance
         }
     }
    
    /// 初始化
    private override init() {
        super.init()
        let options:Dictionary = [CBCentralManagerOptionShowPowerAlertKey:true]
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: options)
    }
    
    func startCheckStatus(block:((_ central:CBCentralManager)->Void)?) {
        self.centralState = block
    }
    
    /// 扫描蓝牙外设 services=nil 为扫描所有的设备
    func scan(_ services:[CBUUID]?, _ options: [String : Any]? = nil,block:((_ central:CBCentralManager,_ peripheral:CBPeripheral,_ advertisementData:Dictionary<String, Any>,_ rssi:NSNumber)->Void)? = nil) {
        didDiscoverPeripheral = block
        serviceUUIDs = services
        centralManager.scanForPeripherals(withServices: services, options: options)
    }
    
    /// 连接外设
    func connect(_ peripheral: CBPeripheral, options: [String: Any]?, stopScanAfterConnected: Bool, serviceUUIDs: [CBUUID]?, characteristicUUIDs: [CBUUID]?,block:((_ stage:DPOptionStage,_ peripheral:CBPeripheral,_ service:CBService?,_ character:CBCharacteristic?,_ error:Error?)->Void)? = nil) {
        connectStageBlock = block
        // 先取消之前连接的外设
        if let printerPeripheral = printerPeripheral {
            centralManager.cancelPeripheralConnection(printerPeripheral)
        }
        self.serviceUUIDs = serviceUUIDs
        self.characteristicUUIDs = characteristicUUIDs
        self.stopScanAfterConnected = stopScanAfterConnected
            
        centralManager.connect(peripheral, options: options)
        peripheral.delegate = self
        if connectStageBlock != nil {
            connectStageBlock!(.connectStart,peripheral,nil,nil,nil)
        }
    }
    
    
    /// 停止扫描
    func stopScan() {
        didDiscoverPeripheral = nil
        centralManager.stopScan()
    }
    
    /// 断开外设连接
    func cancelPeripheralConnect() {
        if printerPeripheral != nil {
            centralManager.cancelPeripheralConnection(printerPeripheral)
        }
    }
}

extension DPBLEManager:CBCentralManagerDelegate {
    // 蓝牙权限更新
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if self.centralState != nil {
            self.centralState!(central)
        }
    }
    
    // 发现外设回调
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if self.didDiscoverPeripheral != nil {
            self.didDiscoverPeripheral!(central,peripheral,advertisementData,RSSI)
        }
    }
    
    // 连接外设成功回调
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        printerPeripheral = peripheral
        if stopScanAfterConnected {
            centralManager.stopScan()
        }
        printerPeripheral.delegate = self
        printerPeripheral.discoverServices(self.serviceUUIDs)
        if connectStageBlock != nil {
            connectStageBlock!(.connectSuccess,peripheral,nil,nil,nil)
        }
    }
    // 连接外设失败回调
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to Bluetooth peripheral:", peripheral.name ?? "Unknown Device")
        if connectStageBlock != nil {
            connectStageBlock!(.connectFail,peripheral,nil,nil,error)
        }
    }
    // 连接外设丢失断开回调
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        printerPeripheral = nil
    }
}

extension DPBLEManager:CBPeripheralDelegate{
    /// 根据服务UUID寻找服务对象
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            if connectStageBlock != nil {
                connectStageBlock!(.seekService,peripheral,nil,nil,error)
            }
            return
        }
        if connectStageBlock != nil {
            connectStageBlock!(.seekService,peripheral,nil,nil,nil)
        }
       
        peripheral.services?.forEach { service in
            peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    /// 在服务对象UUID数组中寻找特定服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        
        
    }
    /// 在一个服务中寻找特征值-
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            if connectStageBlock != nil {
                connectStageBlock!(.seekCharacteristic,peripheral,service,nil,error)
            }
            return
        }
        if connectStageBlock != nil {
            connectStageBlock!(.seekCharacteristic,peripheral,service,nil,nil)
        }
        self.getWriteCharacter(service: service)
        // 开始读取服务数据
        service.characteristics?.forEach { characteristic in
              peripheral.discoverDescriptors(for: characteristic)
              peripheral.readValue(for: characteristic)
          }
    }
    
    // 特性改变回调
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        
        
    }
    // 读取特性中的值
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        
    }
    
    // 写入数据回调
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("写入失败: \(error.localizedDescription)")
        } else {
            print("写入成功")
        }
    }
}
// ---------------- 发现服务特性描述的代理 ------------------
extension DPBLEManager {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            if connectStageBlock != nil {
                connectStageBlock!(.seekDescriptors,peripheral,nil,characteristic,error)
            }
            return
        }
        if connectStageBlock != nil {
            connectStageBlock!(.seekDescriptors,peripheral,nil,characteristic,nil)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: (any Error)?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        
    }
}


extension DPBLEManager {
    
    func getWriteCharacter(service:CBService?) {
        guard let service = service else {
            return
        }
        for j in 0..<service.characteristics!.count {
            let characteristic = service.characteristics![j]
            let properties = characteristic.properties
            /**
             CBCharacteristicPropertyWrite 和 CBCharacteristicPropertyWriteWithoutResponse 类型的特性都可以写入数据，
             但是后者写入完成后，不会回调写入完成的代理方法 {peripheral:didWriteValueForCharacteristic:error:}，
             因此，你也不会收到 block 回调。
             所以首先考虑使用 CBCharacteristicPropertyWrite 的特性写入数据，如果没有这种特性，再考虑使用后者写入吧。
             */
            if properties.contains(.write) {
                self.character = characteristic
                return
            }
        }
    }
    
    /// 读取描述
    func readValue(){
        self.readValue(self.character)
    }
    func readValue(_ characteristic: CBCharacteristic){
        printerPeripheral.readValue(for: characteristic)
    }
    /// 写入
    func writeValue(_ data: Data){
        // withResponse = 写入操作同步 只有在外设确认收到数据后，写入操作才算完成
        self.writeValue(data, for: self.character, type: .withResponse)
    }
    
    private func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        writeCount = 0
        responseCount = 0
        if limitLength <= 0 {
            printerPeripheral.writeValue(data, for: characteristic, type: type)
            writeCount += 1
            return
        }
        if data.count <= limitLength {
            printerPeripheral.writeValue(data, for: characteristic, type: type)
            writeCount += 1
        } else {
            var index = 0
            while index < data.count - limitLength {
                let subData = data.subdata(in: index..<(index + limitLength))
                printerPeripheral.writeValue(subData, for: characteristic, type: type)
                writeCount += 1
                index += limitLength
            }
            let leftData = data.subdata(in: index..<data.count)
            printerPeripheral.writeValue(leftData, for: characteristic, type: type)
            writeCount += 1
        }
    }
}
