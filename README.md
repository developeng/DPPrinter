蓝牙热敏打印机

1.打印机连接

准备工作：

    //添加权限：在info.plist 文件中添加一下键值对
    
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>我们需要您的许可来使用蓝牙功能。</string>
    key>NSBluetoothPeripheralUsageDescription</key>
    <string>我们需要您的许可来使用蓝牙外设。</string>
    

1>：蓝牙扫描：
        
        // 检查蓝牙状态
        DPBLEManager.shared().startCheckStatus { central in
            if central.state == .poweredOn {
                // 开始扫描蓝牙
                DPBLEManager.shared().scan(self.printerServiceUUIDs) { central, peripheral, advertisementData, rssi in
                    // 打印机名称
                    let deviceName = peripheral.name ?? "Unknown Device"
                }
            }
        }
        
2>：连接设备：

        DPBLEManager.shared().connect(peripheral, options: nil, stopScanAfterConnected: true, serviceUUIDs: printerServiceUUIDs, characteristicUUIDs: nil) { stage, peripheral, service, character,
            error in
            switch stage {
            case .connectStart:
                // 开始连接
                break
            case .connectFail:
                // 连接失败
                break
            case .connectSuccess:
                // 蓝牙连接成功
                break
            case .seekService:
                // 搜索服务
                print("打印机服务\(peripheral.services ?? [])")
                break
            case .seekCharacteristic:
                // 搜索特性
                print("服务特性\(String(describing: service?.characteristics))")
                break
            case .seekDescriptors:
                // 搜索描述-打印机连接成功
                break
            }
        }

3>. 打印

        DPBLEManager.shared().writeValue(data)
        

2.58mm小票打印指令： DPEscCommand

<img src="bill.png" alt="img" style="width: 150px; height: 450px;">
    

3.标签打印指令： DPTscCommand

