//
//  ViewController.swift
//  DPPrinter
//
//  Created by developeng on 2023/6/7.
//

import UIKit
import CoreBluetooth

struct DPDeviceInfo {
    var name:String?
    var peripheral:CBPeripheral?
    var advertisementData:Dictionary<String, Any>?
    var rssi:NSNumber?
}

class ViewController: UIViewController {
    
    var scanBtn:UIButton!
    var connectBtn:UIButton!
    var printBtn:UIButton!
    
    var tableView:UITableView!
    var deviceArr:Array<DPDeviceInfo> = Array()
    
    // 热敏打印机服务ID， 一般为 18F0 ，具体根据打印机文档确定
    var printerServiceUUIDs:Array<CBUUID> = [CBUUID(string: "1101"),CBUUID(string: "18F0")]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    
    func setupUI() {
        self.scanBtn = {
            let btn:UIButton = UIButton.init(type: .custom)
            btn.frame = CGRect(x:( self.view.bounds.width-100)/2, y: 100, width: 100, height: 30)
            btn.setTitle("扫描外设", for: .normal)
            btn.setTitleColor(UIColor.red, for: .normal)
            btn.backgroundColor = UIColor.black
            btn.addTarget(self, action: #selector(scan), for: .touchUpInside)
            return btn
        }()
        self.view.addSubview(self.scanBtn)
        
        self.tableView = {
            let tabView:UITableView = UITableView.init(frame: CGRect(x: 0, y: 150, width: self.view.bounds.width, height: self.view.bounds.height - 150), style: .grouped)
            tabView.delegate = self
            tabView.dataSource = self
            tabView.bounces = false
            tabView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            return tabView
        }()
        self.view.addSubview(self.tableView)
    }
}

extension ViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let infoModel:DPDeviceInfo = self.deviceArr[indexPath.row]
        self.connect(infoModel.peripheral)
        
    }
}

extension ViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.deviceArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let infoModel:DPDeviceInfo = self.deviceArr[indexPath.row]
        
        let cell:UITableViewCell = tableView .dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = infoModel.name
        return cell
    }

}

extension ViewController {
    
    // 扫描设备
    @objc func scan() {
        self.deviceArr.removeAll()
        DPBLEManager.shared().scanForPeripherals(printerServiceUUIDs) { central, peripheral, advertisementData, rssi in
            
            // 打印机名称
            let deviceName = peripheral.name ?? "Unknown Device"
            // 检查设备的服务
            var infoModel:DPDeviceInfo = DPDeviceInfo()
            infoModel.name = deviceName
            infoModel.peripheral = peripheral
            infoModel.advertisementData = advertisementData
            infoModel.rssi = rssi
            self.deviceArr.append(infoModel)
            self.tableView.reloadData()
        }
    }
    
    // 连接设备
    @objc func connect(_ peripheral:CBPeripheral?) {
        
        guard let peripheral = peripheral else {
            return
        }
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
                print("服务描述\(String(describing: character?.description))")
                self.alert(peripheral.name!)
                break
            }
        }
    }
    
    // 打印
    @objc func startPrint(data:Data?) {
        guard let data = data else {
            return
        }
        DPBLEManager.shared().writeValue(data)
    }
    
}

// 打印指令
extension ViewController {
    
    func alert(_ name:String) {
        let alertController = UIAlertController(title: "连接打印机\(name)成功",
                        message: "打印指令调试？", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let okIAction = UIAlertAction(title: "ESC指令", style: .default, handler: {
            action in
            print("点击了ESC指令")
            self.escTest()
        })
        let okIIAction = UIAlertAction(title: "TSC指令", style: .default, handler: {
            action in
            print("点击了TSC指令")
        })
        alertController.addAction(cancelAction)
        alertController.addAction(okIAction)
        alertController.addAction(okIIAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

