//
//  DPTscCommand.swift
//  DPPrinter
//
//  Created by developeng on 2023/7/10.
//

import Foundation
import CoreFoundation
import UIKit

// TSC 指令

// MARK: - 枚举定义
enum DPResponse {
    case on
    case off
    case batch
}
// MARK: - 标签打印指令
class DPTscCommand {

    var printerData: NSMutableData = NSMutableData()

    /**
     * 方法说明：换行
     */
    private func addAd() {
        let AD = "\r\n"
        if let data = AD.data(using: .utf8) {
            printerData.append(data)
        }
    }

    /**
     * 方法说明：设置标签尺寸的宽和高
     * @param width  标签宽度
     * @param height 标签高度
     */
    func addSize(width: Int, height: Int) {
        let SIZE = "SIZE \(width) mm,\(height) mm"
        if let data = SIZE.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：设置标签间隙尺寸 单位mm
     * @param m    间隙长度
     * @param n    间隙偏移
     */
    func addGap(m: Int, n: Int) {
        let GAP = "GAP \(m) mm,\(n) mm"
        if let data = GAP.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：设置标签原点坐标
     * @param x  横坐标
     * @param y  纵坐标
     */
    func addReference(x: Int, y: Int) {
        let REFERENCE = "REFERENCE \(x),\(y)"
        if let data = REFERENCE.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：设置打印速度
     * @param speed  打印速度
     */
    func addSpeed(speed: Int) {
        let SPEED = "SPEED \(speed)"
        if let data = SPEED.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：设置打印浓度。0-15设置范围
     * @param density  浓度 0: 使用最淡的打印浓度,15:使用最深的打印浓度
     */
    func addDensity(density: Int) {
        let DENSITY = "DENSITY \(density)"
        if let data = DENSITY.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：设置打印方向
     * @param direction  方向
     */
    func addDirection(direction: Int) {
        let DIRECTION = "DIRECTION \(direction)"
        if let data = DIRECTION.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：清除打印缓冲区
     */
    func addCls() {
        let CLS = "CLS"
        if let data = CLS.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:在标签上绘制文字
     * @param x 横坐标
     * @param y 纵坐标
     * @param font  字体类型
     * @param rotation  旋转角度
     * @param xScal  横向放大(1-10)
     * @param yScal  纵向放大(1-10)
     * @param text   文字字符串
     */
    func addText(x: Int, y: Int, font: String, rotation: Int, xScal: Int, yScal: Int, text: String) {
        let TEXT = "TEXT \(x),\(y),\"\(font)\",\(rotation),\(xScal),\(yScal),\"\(text)\""
        let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        if let data = TEXT.data(using: enc) {
            printerData.append(data)
            addAd()
        }
    }
    /*
     BITMAP X, Y, width, height, mode, bitmap data
     参 数 说 明
     x 点阵影像的水平启始位置
     y 点阵影像的垂直启始位置
     width 影像的宽度，以 byte 表示
     height 影像的高度，以点(dot)表示
     mode 影像绘制模式
     0 OVERWRITE
     1 OR
     2 XOR
     bitmap data 影像数据
     */
    func addBitmap(x: Int, y: Int, width: Int, height: Int, mode: Int, data: Data) {
        let BITMAP = "BITMAP \(x),\(y),\(width),\(height),\(mode),\(data.hexEncodedString())"
        if let data = BITMAP.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }

    func addBitmap(x: Int, y: Int, mode: Int, width: Int, image: UIImage) {
        if let imageData = image.pngData() {
            addBitmap(x: x, y: y, width: width, height: 100, mode: mode, data: imageData)
        }
    }

    func addBitmap(x: Int, y: Int, mode: Int, image: UIImage) {
        if let imageData = image.pngData() {
            addBitmap(x: x, y: y, width: 100, height: 100, mode: mode, data: imageData)
        }
    }
    /**
     * 方法说明:在标签上绘制一维条码
     * @param x 横坐标
     * @param y 纵坐标
     * @param barcodeType 条码类型
     * @param height  条码高度，默认为40
     * @param readable  是否可识别，0:  人眼不可识，1:   人眼可识
     * @param rotation  旋转角度，条形码旋转角度，顺时钟方向，0不旋转，90顺时钟方向旋转90度，180顺时钟方向旋转180度，270顺时钟方向旋转270度
     * @param narrow 默认值2，窄 bar  宽度，以点(dot)表示
     * @param wide 默认值4，宽 bar  宽度，以点(dot)表示
     * @param content   条码内容
     BARCODE X,Y,"code type",height,human readable,rotation,narrow,wide,"code"
     BARCODE 100,100,"39",40,1,0,2,4,"1000"
     "code type":
     EAN13("EAN13"),
     EAN8("EAN8"),
     UPCA("UPCA"),
     ITF14("ITF14"),
     CODE39("39"),
     CODE128("128"),
     */
    func addBarcode(x: Int, y: Int, barcodeType: String, height: Int, readable: Int, rotation: Int, narrow: Int, wide: Int, content: String) {
        let BARCODE = "BARCODE \(x),\(y),\"\(barcodeType)\",\(height),\(readable),\(rotation),\(narrow),\(wide),\"\(content)\""
        if let data = BARCODE.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:在标签上绘制QRCode二维码
     * @param x 横坐标
     * @param y 纵坐标
     * @param ecclever 选择QRCODE纠错等级,L为7%,M为15%,Q为25%,H为30%
     * @param cellwidth  二维码宽度1~10，默认为4
     * @param mode  默认为A，A为Auto,M为Manual
     * @param rotation  旋转角度，QRCode二维旋转角度，顺时钟方向，0不旋转，90顺时钟方向旋转90度，180顺时钟方向旋转180度，270顺时钟方向旋转270度
     * @param content   条码内容
     * QRCODE X,Y ,ECC LEVER ,cell width,mode,rotation, "data string"
     * QRCODE 20,24,L,4,A,0,"佳博集团网站www.Gprinter.com.cn"
     */
    func addQRCode(x: Int, y: Int, ecclever: String, cellwidth: Int, mode: String, rotation: Int, content: String) {
        let QRCODE = "QRCODE \(x),\(y),\(ecclever),\(cellwidth),\(mode),\(rotation),\"\(content)\""
        if let data = QRCODE.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：执行打印
     * @param m 指定打印的份数 1≤m≤65535
     * @param n 每张标签需重复打印的张数 1≤n≤65535
     */
    func addPrint(m: Int, n: Int) {
        let PRINT = "PRINT \(m),\(n)"
        if let data = PRINT.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:获得打印命令
     */
    func getCommand() -> Data {
        return printerData as Data
    }
    /**
     * 方法说明:设置打印机剥离模式
     * @param peel ON/OFF  是否开启
     */
    func addPeel(peel: String) {
        let PEEL = "SET PEEL \(peel)"
        if let data = PEEL.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:设置打印机撕离模式
     * @param tear ON/OFF 是否开启
     */
    func addTear(tear: String) {
        let TEAR = "SET TEAR \(tear)"
        if let data = TEAR.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：打开钱箱命令,CASHDRAWER m,t1,t2
     * @param m  钱箱号 m      0，48  钱箱插座的引脚2        1，49  钱箱插座的引脚5
     * @param t1   高电平时间0 ≤ t1 ≤ 255输出由t1和t2设定的钱箱开启脉冲到由m指定的引脚
     * @param t2   低电平时间0 ≤ t2 ≤ 255输出由t1和t2设定的钱箱开启脉冲到由m指定的引脚
     */
    func addCashdrawer(m: Int, t1: Int, t2: Int) {
        let CASHDRAWER = "CASHDRAWER \(m),\(t1),\(t2)"
        if let data = CASHDRAWER.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：该指令用于设定黑标高度及定义标签印完后标签额外送出的长度 (BLINE 指令不与 GAP 指令同时使用)
     * @param m  黑标高度 0≤m≤25.4
     * @param n   额外送出纸张长度  n≤标签纸纸张长度
     */
    func addBline(m: Int, n: Int) {
        let BLINE = "BLINE \(m) mm,\(n) mm"
        if let data = BLINE.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：该指令用于控制打印机进一张标签纸
     */
    func addFormfeed() {
        let FORMFEED = "FORMFEED"
        if let data = FORMFEED.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：在使用含有间隙或黑标的标签纸时，若不能确定第一张标签纸是否在正确打印位 置时，此指令可将标签纸向前推送至下一张标签纸的起点开始打印。标签尺寸和 间隙需要在本条指令前设置。
     */
    func addHome() {
        let HOME = "HOME"
        if let data = HOME.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明：设置蜂鸣器
     * @param level 频率 音阶:0-9
     * @param interval  时间ms  间隔时间:1-4095
     */
    func addSound(level: Int, interval: Int) {
        let SOUND = "SOUND \(level),\(interval)"
        if let data = SOUND.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:打印自检页，打印测试页
     */
    func addSelfTest() {
        let SELFTEST = "SELFTEST"
        if let data = SELFTEST.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:在标签上绘制黑块，画线
     * @param x 起始横坐标
     * @param y 起始纵坐标
     * @param width 线宽，以点(dot)表示
     * @param height 线高，以点(dot)表示
     */
    func addBar(x: Int, y: Int, width: Int, height: Int) {
        let BAR = "BAR \(x),\(y),\(width),\(height)"
        if let data = BAR.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:在标签上绘制矩形
     * @param xStart 起始横坐标
     * @param yStart 起始纵坐标
     * @param xEnd 终点横坐标
     * @param yEnd 终点纵坐标
     * @param lineThickness 矩形框线厚度或宽度，以点(dot)表示
     */
    func addBox(xStart: Int, yStart: Int, xEnd: Int, yEnd: Int, lineThickness: Int) {
        let BOX = "BOX \(xStart),\(yStart),\(xEnd),\(yEnd),\(lineThickness)"
        if let data = BOX.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:将指定的区域反向打印（黑色变成白色，白色变成黑色）
     * @param xStart 起始横坐标
     * @param yStart 起始横坐标
     * @param xWidth X坐标方向宽度，dot为单位
     * @param yHeight Y坐标方向高度，dot为单位
     */
    func addReverse(xStart: Int, yStart: Int, xWidth: Int, yHeight: Int) {
        let REVERSE = "REVERSE \(xStart),\(yStart),\(xWidth),\(yHeight)"
        if let data = REVERSE.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     * 方法说明:查询打印机状态<ESC>!?
        *询问打印机状态指令为立即响应型指令，该指令控制字符是以<ESC> (ASCII 27=0x1B, escape字符)为控制字符.!(ASCII 33=0x21),?(ASCII 63=0x3F)
        *即使打印机在错误状态中仍能透过 RS-232  回传一个 byte  资料来表示打印机状态，若回传值为 0  则表示打印
        *机处于正常的状态
     */
    func queryPrinterStatus() {
        let ESC = "<ESC>!?"
        if let data = ESC.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
    /**
     *  方法说明: 打印机打印完成时，自动返回状态。可用于实现连续打印功能
     *  @param response  自动返回状态  <a>@see Response</a>
     *                  OFF     关闭自动返回状态功能
     *                  ON      开启自动返回状态功能
     *                  BATCH   全部打印完成后返回状态
     */
    func addQueryPrinterStatus(response: DPResponse) {
        let state: String
        switch response {
        case .on:
            state = "ON"
        case .off:
            state = "OFF"
        case .batch:
            state = "BATCH"
        }
        let RESPONSE = "SET RESPONSE \(state)"
        if let data = RESPONSE.data(using: .utf8) {
            printerData.append(data)
            addAd()
        }
    }
}



// MARK: - 数据扩展

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
