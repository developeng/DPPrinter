//
//  ViewControllerEx.swift
//  DPPrinter
//
//  Created by developeng on 2024/11/6.
//

import Foundation
import UIKit

// 热敏小票测试数据
extension ViewController {
    
    func escTest() {
        let command:DPEscCommand = DPEscCommand()
        command.isChangeSpace = false
        command.appendText("单据标题",alignment: .center,fontSize: .titleHMiddle, fontStyle: .bold)
        command.appendText("新时器烤肉（虚拟测试门店9090）")
        command.appendText("地址：金翠芳")
        command.appendText("电话：10086")
        command.appendText("下单时间：2024-22-06 14:27:24")
        command.appendText("订单编号：112233445566")
        command.appendSeparatorLine()
        command.appendText("商品名称", middle: "数量", right: "金额", isTitle: true)
        command.appendSolidLine()
        command.appendText("香菇饭", middle: "2", right: "28")
        command.appendSolidLine()
        command.appendText("餐位费", middle: "2", right: "2")
        command.appendSolidLine()
        command.appendText("白菜饺子", middle: "2", right: "20")
        command.appendSolidLine()
        command.appendText("孜然羊肉", middle: "2", right: "29")
        command.appendSolidLine()
        
        command.appendText("合计金额", value: "100",titleFontStyle: .bold, valueFontStyle: .bold)
        command.appendDottedLine()
        command.appendText("优惠卡", value: "-12")
        command.appendSolidLine()
        command.appendText("实付金额", value: "88（刷卡）",titleFontStyle: .bold, valueFontStyle: .bold)
        command.appendDottedLine()
        command.appendSolidLine(withText: "二维码")
//        command.appendQRCode(withInfo: "https://www.baidu.com/", size: 7)
        command.appendQRImgCode(withInfo: "https://www.baidu.com/",maxWidth: 264)
        command.appendSolidLine(withText: "公众号", symbol: "&")
        command.appendImage(UIImage(named: "gong_zhong_hao"))
        
        command.printCutPaper(.full, num: 5)
        self.startPrint(data: command.printerData as Data)
    }
}

// 标签测试数据
extension ViewController {
    
    func tscTest() {
        //如果打印多张，循环添加printer内指令即可
        let printer:DPTscCommand = DPTscCommand()
        printer.addSize(width: 40, height: 30)
        printer.addGap(m: 2, n: 0)
        printer.addReference(x: 0, y: 0)
        printer.addTear(tear: "ON")
        printer.addQueryPrinterStatus(response: .on)
        printer.addDensity(density: 10)
        printer.addCls()
        
        printer.addText(x: 0, y: 5, font: "TSS24.BF2", rotation: 0, xScal: 1, yScal: 2, text: "商品名称")
        printer.addText(x: 0, y: 59, font: "TSS24.BF2", rotation: 0, xScal: 1, yScal: 1, text: "总价:￥100.00")
        printer.addText(x: 0, y: 90, font: "TSS24.BF2", rotation: 0, xScal: 1, yScal: 1, text: "哈哈操作")
        printer.addText(x: 140, y: 90, font: "TSS24.BF2", rotation: 0, xScal: 1, yScal: 1, text: "2024-09-28 生产")
        
        printer.addBarcode(x: 0, y: 130, barcodeType: "128", height: 50, readable: 0, rotation: 0, narrow: 3, wide: 3, content: "1234567890")
        printer.addText(x: 0 + Int(barLeft(code: "1234567890")) , y: 185, font: "TSS24.BF2", rotation: 0, xScal: 1, yScal: 1, text: "1234567890")
        printer.addPrint(m: 1, n: 1)
        
        self.startPrint(data: printer.printerData as Data)
    }
    //bar居中处理
     func barLeft(code:String) -> Int32 {
        return  (300 - Int32(300 / 25 * code.count)) / 2
    }
}

