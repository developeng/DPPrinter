蓝牙热敏打印机

1.打印机连接

1>：蓝牙扫描：

        DPBLEManager.shared().scanForPeripherals(printerServiceUUIDs) { central, peripheral, advertisementData, rssi in
            // 打印机名称
            let deviceName = peripheral.name ?? "Unknown Device"
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
    
    ![Example Image](bill.png)

3.标签打印指令： DPTscCommand

