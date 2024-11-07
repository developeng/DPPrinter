//
//  DPEscCommand.swift
//  DPPrinter
//
//  Created by developeng on 2023/7/10.
//

import UIKit

// ESC 指令 58mm

enum DPTextAlignment: UInt8 {
    case left = 0
    case center = 1
    case right = 2
}

enum DPFontSize: UInt8 {
    case titleSmall = 0
    case titleMiddle = 1
    case titleHMiddle = 2
    case titleBig = 3
}

enum DPFontStyle: UInt8 {
    case bold = 1
    case boldCancel = 0
}

enum DPCutPaperModel: UInt8 {
    case full = 66
    case partial = 67
}

enum DPPrinterModel: UInt8 {
    case mode1 = 1
    case mode2 = 2
    // 根据需要添加更多模式
}

// MARK: - 基本指令（采用16进制）
class DPEscCommand {
    private static let kHLMargin: Int = 20
    private static let kHLPadding: Int = 2
    private static let kWHPreviewWidth: CGFloat = 380.0
    private static let kWHPageWidth: CGFloat = 384.0 // 纸张宽度 384 可显示16个汉字
    
    var printerData: NSMutableData = NSMutableData()
    
    var isChangeSpace: Bool = false
    var isFontBold: Bool = false
    
    init() {
        self.setup()
    }
    // 初始化打印机
    func setup() {
        printerData = NSMutableData()
        
        // 初始化打印机
        let initBytes: [UInt8] = [0x1B, 0x40]
        printerData.append(initBytes, length: initBytes.count)
        
        // 2. 设置行间距为1/6英寸，约34个点
        let lineSpace: [UInt8] = [0x1B, 0x32]
        printerData.append(lineSpace, length: lineSpace.count)
        
        // 3. 设置字体: 标准0x00，压缩0x01
        let fontBytes: [UInt8] = [0x1B, 0x4D, 0x00]
        printerData.append(fontBytes, length: fontBytes.count)
    }
    
    // 换行
    func appendNewLine() {
        if isChangeSpace {
            setLineSpace(8)
        }
        let bytes: [UInt8] = [0x0A]
        printerData.append(bytes, length: bytes.count)
    }
    // 设置行间距
    func setLineSpace(_ points: Int) {
        let bytes: [UInt8] = [0x1B, 0x33, UInt8(points)]
        printerData.append(bytes, length: bytes.count)
    }
    
    // 回车
    func appendReturn() {
        let bytes: [UInt8] = [0x0D]
        printerData.append(bytes, length: bytes.count)
    }
    // 设置对齐方式
    func setAlignment(_ alignment: DPTextAlignment) {
        let bytes: [UInt8] = [0x1B, 0x61, UInt8(alignment.rawValue)]
        printerData.append(bytes, length: bytes.count)
    }
    // 设置字体大小
    func setFontSize(_ fontSize: DPFontSize) {
        let bytes: [UInt8] = [0x1D, 0x21, UInt8(fontSize.rawValue)]
        printerData.append(bytes, length: bytes.count)
    }
    // 设置字体类型（是否加粗）
    func setFontStyle(_ fontStyle: DPFontStyle) {
        let fontSizeBytes: [UInt8] = [0x1B, 0x45, UInt8(fontStyle.rawValue)]
        printerData.append(fontSizeBytes, length: fontSizeBytes.count)
    }
    /** 设置文本
     *  text = 文本内容
     *  maxChar = 限制最大显示字符数
     */
    func setText(_ text: String, _ maxChar: Int = 0) {
        let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        if maxChar == 0 {
            if let data = text.data(using: enc) {
                printerData.append(data)
            }
            return
        }
        if let data = text.data(using: enc), data.count > maxChar {
            let finalData = data.subdata(in: 0..<(maxChar - 1))
            if let finalText = String(data: finalData, encoding: enc) {
                setText(finalText + "...")
            }
        } else {
            setText(text)
        }
    }
    
    func setOffsetText(_ text: String, fontSize: DPFontSize) {
        let valueWidth = getValueWidth(text, fontSize: fontSize)
        setOffset(Int(DPEscCommand.kWHPreviewWidth) - valueWidth)
        setText(text)
    }
    // 计算文本宽度
    private func getValueWidth(_ text: String, fontSize: DPFontSize) -> Int {
        let valueWidth = ceil(CGFloat(judgeNum(text, fontSize: fontSize)) * (DPEscCommand.kWHPreviewWidth / 32.0))
        return Int(valueWidth)
    }
    // 计算文本占用字符空间-（最窄字体=>汉字=2/英文=1）
    private func judgeNum(_ str: String, fontSize: DPFontSize) -> Int {
        var len = 0
        for char in str.utf16 {
            if (char >= 0x4e00 && char <= 0x9fff) ||
                (char >= 0x3000 && char <= 0x303f) ||
                (char >= 0xff00 && char <= 0xffef) {
                len += 2
            } else {
                len += 1
            }
        }
        
        if fontSize == .titleMiddle || fontSize == .titleHMiddle {
            return 2 * len
        } else if fontSize == .titleBig {
            return 4 * len
        }
        return len
    }
    // 设置文本偏移量
    func setOffset(_ offset: Int) {
        let remainder = offset % 256
        let consult = offset / 256
        let spaceBytes: [UInt8] = [0x1B, 0x24, UInt8(remainder), UInt8(consult)]
        printerData.append(spaceBytes, length: spaceBytes.count)
    }
    
    /**
     *  设置二维码模块大小
     *
     *  @param size  1<= size <= 16,二维码的宽高相等
     */
    func setQRCodeSize(_ size: Int) {
        let QRSize: [UInt8] = [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, UInt8(size)]
        printerData.append(QRSize, length: QRSize.count)
    }
    /**
     *  设置二维码的纠错等级
     *
     *  @param level 48 <= level <= 51
     */
    func setQRCodeErrorCorrection(_ level: Int) {
        let levelBytes: [UInt8] = [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, UInt8(level)]
        printerData.append(levelBytes, length: levelBytes.count)
    }
    
    /**
     *  将二维码数据存储到符号存储区
     * [范围]:  4≤(pL+pH×256)≤7092 (0≤pL≤255,0≤pH≤27)
     * cn=49
     * fn=80
     * m=48
     * k=(pL+pH×256)-3, k就是数据的长度
     *
     *  @param info 二维码数据
     */
    func setQRCodeInfo(_ info: String) {
        let kLength = info.utf8.count + 3
        let pL = kLength % 256
        let pH = kLength / 256
        let dataBytes: [UInt8] = [0x1D, 0x28, 0x6B, UInt8(pL), UInt8(pH), 0x31, 0x50, 48]
        printerData.append(dataBytes, length: dataBytes.count)
        if let infoData = info.data(using: .utf8) {
            printerData.append(infoData)
        }
    }
    /**
     *  打印之前存储的二维码信息
     */
    func printStoredQRData() {
        let printBytes: [UInt8] = [0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 48]
        printerData.append(printBytes, length: printBytes.count)
    }
    /**
     *  打印并走纸多少行
     *
     *  @param n 走纸n行
     */
    func appendGoLine(_ n: Int) {
        let line: [UInt8] = [0x1B, 0x64, UInt8(n)]
        printerData.append(line, length: line.count)
    }
    /**
     *  切纸
     *
     *  @param n 走纸n行
     */
    func printCutPaper(_ model: DPCutPaperModel, num: Int) {
        if model == .full {
            let cut: [UInt8] = [0x1D, 0x56, UInt8(model.rawValue), UInt8(num)]
            printerData.append(cut, length: cut.count)
        } else {
            let cut: [UInt8] = [0x1D, 0x56, UInt8(model.rawValue)]
            printerData.append(cut, length: cut.count)
        }
    }
    
    /**
     *  切换打印模式（适用于标签热敏一体的打印机）
     *  @param n 走纸n行
     */
    static func changeWorkMode(_ mode: DPPrinterModel) -> Data {
        let printBytes: [UInt8] = [0x1F, 0x1B, 0x1F, 0xFC, 0x01, 0x02, 0x03, UInt8(mode.rawValue)]
        return Data(printBytes)
    }
    // 获取打印机状态指令
    static func printerState() -> Data {
        let printBytes: [UInt8] = [0x10, 0x04, 0x02]
        return Data(printBytes)
    }
}

// 功能方法
// MARK: - 文本
extension DPEscCommand {
    /// 单行文字
    func appendText(_ text: String, alignment: DPTextAlignment = .left, fontSize: DPFontSize = .titleSmall, fontStyle: DPFontStyle = .boldCancel) {
        // 设置样式
        setAlignment(alignment)
        setLineSpace(isChangeSpace ? 8 : 36)
        setFontSize(fontSize)
        setFontStyle(isFontBold ? .bold : fontStyle)
        setText(text)
        //恢复初始状态
        setFontStyle(.boldCancel)
        setFontSize(.titleSmall)
        appendNewLine()
    }
    /**
     *  名称信息 ： 2列 （靠两侧对齐）
     *  @param title   左侧文本
     *  @param value 右侧文本
     */
    func appendText(_ title: String, value: String, fontSize: DPFontSize = .titleSmall, titleFontStyle: DPFontStyle = .boldCancel, valueFontStyle: DPFontStyle = .boldCancel) {
        // 1. 设置对齐方式
        setAlignment(.left)
        // 2. 设置字号
        setFontSize(fontSize)
        // 3. 设置是否加粗
        setFontStyle(isFontBold ? .bold : titleFontStyle)
        setLineSpace(isChangeSpace ? 8 : 36)
        
        // 4. 设置标题内容
        setText(title)
        
        let titleWidth = judgeNum(title, fontSize: fontSize)
        let valueWidth = judgeNum(value, fontSize: fontSize)
        if titleWidth + valueWidth >= 31 {
            appendNewLine()
        }
        // 5. 设置value
        setFontStyle(isFontBold ? .bold : valueFontStyle)
        setOffsetText(value, fontSize: fontSize)
        // 放弃加粗
        setFontStyle(.boldCancel)
        setFontSize(.titleSmall)
        appendNewLine()
    }
    /**
     *  名称信息 ： 2列 （全靠左对齐）
     *  @param title   左侧文本
     *  @param value 右侧文本
     */
    func appendText(_ title: String, value: String, valueOffset: Int, fontSize: DPFontSize = .titleSmall) {
        // 1. 设置对齐方式
        setAlignment(.left)
        // 2. 设置字号
        setFontSize(fontSize)
        // 3. 设置标题内容
        setText(title)
        // 4. 设置内容偏移量
        setOffset(valueOffset)
        // 5. 设置实际值
        setText(value)
        // 6. 换行
        appendNewLine()
        if fontSize != .titleSmall {
            appendNewLine()
        }
    }
    /**
     *  名称信息 ： 3列
     *  @param left   左侧文本
     *  @param middle 中间文本
     *  @param right 右侧文本
     *  @param middleOffset 中间文本距离最左边的距离（偏移量）
     */
    func appendText(_ left: String, middle: String, right: String, isTitle: Bool = false, fontSize: DPFontSize = .titleSmall, fontStyle: DPFontStyle = .boldCancel, middleOffset:Int = 220) {
        setAlignment(.left)
        setFontSize(fontSize)
        setFontStyle(isFontBold ? .bold : fontStyle)
        // 标题比内容多偏移15
        let offset = isTitle ? 0 : 15
        // 左侧文本
        setText(left)
        let leftWidth = judgeNum(left, fontSize: fontSize)
        if leftWidth % 32 > 17 {
            appendNewLine()
        }
        // 中间文本
        setOffset(middleOffset + offset)
        setText(middle)
        // 右侧文本
        setOffsetText(right, fontSize: fontSize)
        // 恢复设置
        setFontStyle(.boldCancel)
        setFontSize(.titleSmall)
        appendNewLine()
    }
}
// MARK: - 打印图片
extension DPEscCommand {
   
    func appendImage(_ image: UIImage?, alignment: DPTextAlignment = .center, maxWidth: CGFloat = kWHPageWidth , quality: CGFloat = 0.5) {
        guard let image = image else {
            return
        }
        // 1. 设置图片对齐方式
        setAlignment(alignment)
        // 2. 设置图片
        let newImage =  image.imageWithScale(maxWidth: maxWidth, quality: quality)
//        let newImage =  image.imageWithscaleMaxWidth(maxWidth, quality: quality)
        // 使用压缩后的图像数据
        if let imageData = newImage?.bitmapData() {
            print(imageData.count)
            printerData.append(imageData)
            // 3. 换行
            appendNewLine()
            // 4. 打印图片后，恢复文字的行间距
            let lineSpace: [UInt8] = [0x1B, 0x32]
            printerData.append(lineSpace, length: lineSpace.count)
        }
    }
}

// MARK: - 条码
extension DPEscCommand {
    /**
     * 方法说明：设置条码可识别字符，选择HRI字符的打印位置
     * @param n  可识别字符位置，0, 48  不打印 1, 49  条码上方 2, 50  条码下方 3, 51  条码上、下方都打印
     */
    func addSetBarcodeHRPosition(_ n: Int) {
        let bytes: [UInt8] = [0x1D, 0x48, UInt8(n)]
        printerData.append(bytes, length: bytes.count)
    }
    
    /**
     * 方法说明：设置条码字符种类，选择HRI使用字体
     */
    func addSetBarcodeHRIFont() {
        let bytes: [UInt8] = [0x1D, 0x66, 0x48]
        printerData.append(bytes, length: bytes.count)
    }
    
    /**
      * 方法说明：设置条码高度
      * @param n 高度 条码高度为n点，默认为40
      */
     func addSetBarcodeHeight(_ n: Int) {
         let bytes: [UInt8] = [0x1D, 0x68, UInt8(n)]
         printerData.append(bytes, length: bytes.count)
     }
    
    /**
     * 方法说明：设置条码单元宽度，不用设置，使用打印机内部默认值
     * @param n 条码宽度 2 ≤n ≤6
     */
    func addSetBarcodeWidth(_ n: Int) {
        let bytes: [UInt8] = [0x1D, 0x77, UInt8(n)]
        printerData.append(bytes, length: bytes.count)
    }
    
    /**
      * 方法说明：添加CODE128条形码 (打印机如果支持条码指令)
      * @param info 条形码信息
      */
    func addCODE128(_ info: String) {
        let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        if let data = info.data(using: enc) {
            let dataBytes: [UInt8] = [0x1D, 0x6B, 73, UInt8(data.count + 2), 123, 65]
            printerData.append(dataBytes, length: dataBytes.count)
            printerData.append(data)
        }
    }
    
    /**
     *  添加条形码图片
     *  ⚠️提醒：这种打印条形码的方式，是自己生成条形码图片，然后用位图打印图片
     *
     *  @param info      条形码中的信息
     *  @param alignment 图片对齐方式
     *  @param maxWidth  图片最大宽度
     */
     func appendBarCode(withInfo info: String, alignment: DPTextAlignment, maxWidth: CGFloat = 300) {
         if let barImage = UIImage.barCodeImage(with: info) {
             appendImage(barImage, alignment: alignment, maxWidth: maxWidth, quality: 0.5)
         }
     }
}
// MARK: - 二维码
extension DPEscCommand {
    /**
     *  添加二维码
     *  ✅推荐：这种方式使用的是打印机的指令生成二维码并打印机，所以比较推荐这种方式
     *
     *  @param info      二维码中的信息
     *  @param size      二维码大小，取值范围 1 <= size <= 16
     *  @param alignment 设置图片对齐方式
     */
    func appendQRCode(withInfo info: String, size: Int = 7, alignment: DPTextAlignment = .center) {
        setAlignment(alignment)
        setQRCodeSize(size)
        setQRCodeErrorCorrection(48)
        setQRCodeInfo(info)
        printStoredQRData()
        appendNewLine()
    }

    /**
     *   添加二维码图片(部分打印机不支持二维码可采用此方法)
     *  ⚠️提醒：这种打印条二维码的方式，是自己生成二维码图片，然后用位图打印图片
     *
     *  @param info        二维码中的信息
     *  @param centerImage 二维码中间的图片
     *  @param alignment   对齐方式
     *  @param maxWidth    二维码的最大宽度
     */
    func appendQRImgCode(withInfo info: String, centerImage: UIImage? = nil, alignment: DPTextAlignment = .center, maxWidth: CGFloat = 264) {
        let qrImage = UIImage.createQRCode(with: info, logoImage: centerImage)
        appendImage(qrImage, alignment: alignment, maxWidth: maxWidth, quality: 0.5)
    }
    
}
// MARK: - 其他
extension DPEscCommand {
    // 分割线
    func appendSeparatorLine() {
         setAlignment(.center)
         setFontSize(.titleSmall)
         let line = "--------------------------------\n"
         let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
         if let data = line.data(using: enc) {
             printerData.append(data)
         }
     }
    // 分割线
    func appendSplitLine() {
         setAlignment(.center)
         setFontSize(.titleSmall)
         let line = "— —— —— —— —— —— ——\n"
         let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
         if let data = line.data(using: enc) {
             printerData.append(data)
         }
     }
    // 分割线
    func appendDottedLine() {
         setAlignment(.center)
         setFontSize(.titleSmall)
         let line = "===============================\n"
         let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
         if let data = line.data(using: enc) {
             printerData.append(data)
         }
     }
    
    func appendSolidLine() {
         setAlignment(.left)
         setFontSize(.titleSmall)
         let line = "————————————————\n"
         let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
         if let data = line.data(using: enc) {
             printerData.append(data)
         }
     }
   
    /**
     *  带文本的横线分割线
     *  例如： ------------文本-------------
     */
    func appendSolidLine(withText text: String) {
        setAlignment(.left)
        setFontSize(.titleSmall)
        let textWidth = getValueWidth(text, fontSize: .titleSmall)
        let count = (DPEscCommand.kWHPageWidth - CGFloat(textWidth)) * 16 / DPEscCommand.kWHPageWidth / 2.0

        var leftLine = ""
        var rightLine = ""
        for _ in 0..<Int(ceil(count)) {
            leftLine.append("—")
        }
        for _ in 0..<Int(floor(count)) {
            rightLine.append("—")
        }
        let enc: String.Encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        if let dataI = leftLine.data(using: enc),
           let dataII = rightLine.data(using: enc) {
            printerData.append(dataI)
            setText(text)
            printerData.append(dataII)
        }
    }
    /**
     *  带文本的自定义分隔符分割线
     *  例如： ########文本#######
     */
    func appendSolidLine(withText text: String, symbol: String) {
        setAlignment(.left)
        setFontSize(.titleSmall)
        let symbolCount = judgeNum(symbol, fontSize: .titleSmall)
        let textWidth = getValueWidth(text, fontSize: .titleSmall)
        let count = (DPEscCommand.kWHPageWidth - CGFloat(textWidth)) * 16 / DPEscCommand.kWHPageWidth / CGFloat(symbolCount)

        var leftLine = ""
        var rightLine = ""
        for _ in 0..<Int(round(count)) {
            leftLine.append(symbol)
        }
        for _ in 0..<Int(floor(count)) {
            rightLine.append(symbol)
        }
        setText(leftLine)
        setText(text)
        setText(rightLine)
    }
}


