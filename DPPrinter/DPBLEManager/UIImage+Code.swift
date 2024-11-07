//
//  UIImage+Code.swift
//  DPPrinter
//
//  Created by developeng on 2024/11/6.
//

import UIKit
import CoreImage

// 生成 条码及二维码图片
extension UIImage {

    // MARK: - Bar Code Image

    static func barCodeImage(with info: String) -> UIImage? {
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else {
            return nil
        }

        filter.setDefaults()
        guard let data = info.data(using: .utf8) else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        guard let outputImage = filter.outputImage else {
            return nil
        }
        return createNonInterpolatedUIImage(from: outputImage, withSize: 300)
    }

    // MARK: - QR Code Image

    static func qrCodeImage(with info: String, centerImage: UIImage?, width: CGFloat) -> UIImage? {
        guard let infoData = info.data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }

        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        qrFilter.setValue(infoData, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        guard let qrImage = qrFilter.outputImage else {
            return nil
        }
        guard let codeImage = createNonInterpolatedUIImage(from: qrImage, withSize: width) else {
               return nil
           }

        let rect = CGRect(x: 0, y: 0, width: codeImage.size.width, height: codeImage.size.height)
        UIGraphicsBeginImageContext(rect.size)
        defer { UIGraphicsEndImageContext() }
        codeImage.draw(in: rect)

        if let centerImage = centerImage {
            let logoSize = CGSize(width: rect.size.width * 0.2, height: rect.size.height * 0.2)
            let x = rect.midX - logoSize.width / 2
            let y = rect.midY - logoSize.height / 2
            let logoFrame = CGRect(x: x, y: y, width: logoSize.width, height: logoSize.height)
            UIBezierPath(roundedRect: logoFrame, cornerRadius: 10).addClip()
            centerImage.draw(in: logoFrame)
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Non-Interpolated Image

    static func createNonInterpolatedUIImage(from ciImage: CIImage, withSize size: CGFloat) -> UIImage? {
        let extent = ciImage.extent.integral
        let scale = min(size / extent.width, size / extent.height)
        let width = Int(extent.width * scale)
        let height = Int(extent.height * scale)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }

        let ciContext = CIContext(options: nil)
        guard let bitmapImage = ciContext.createCGImage(ciImage, from: extent) else {
            return nil
        }

        context.interpolationQuality = .none
        context.scaleBy(x: scale, y: scale)
        context.draw(bitmapImage, in: extent)

        guard let scaledImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: scaledImage)
    }

    // MARK: - Image Background Color to Transparent

    func image(bgColorToTransparent image: UIImage, withRed red: CGFloat, green: CGFloat, blue: CGFloat) -> UIImage? {
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)
        let bytesPerRow = imageWidth * 4
        let rgbImageBuf = UnsafeMutablePointer<UInt32>.allocate(capacity: bytesPerRow * imageHeight)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: rgbImageBuf, width: imageWidth, height: imageHeight, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }

        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))

        let pixelNum = imageWidth * imageHeight
        let threshold: UInt32 = 0x99999900
        let redInt = UInt8(red * 255)
        let greenInt = UInt8(green * 255)
        let blueInt = UInt8(blue * 255)

        for i in 0..<pixelNum {
            let pCurPtr = rgbImageBuf + i
            if (pCurPtr.pointee & 0xFFFFFF00) < threshold {
                let ptr = pCurPtr.withMemoryRebound(to: UInt8.self, capacity: 4) { $0 }
                ptr[3] = redInt
                ptr[2] = greenInt
                ptr[1] = blueInt
            } else {
                let ptr = pCurPtr.withMemoryRebound(to: UInt8.self, capacity: 4) { $0 }
                ptr[0] = 0
            }
        }

        let dataProvider = CGDataProvider(dataInfo: nil, data: rgbImageBuf, size: bytesPerRow * imageHeight, releaseData: { _, data, _ in
            free(UnsafeMutableRawPointer(mutating: data))
        })

        guard let imageRef = CGImage(width: imageWidth, height: imageHeight, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            return nil
        }

        return UIImage(cgImage: imageRef)
    }

    // MARK: - Create QR Code with Logo

    static func createQRCode(with targetString: String, logoImage: UIImage?) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setDefaults()
        guard let targetData = targetString.data(using: .utf8, allowLossyConversion: true) else {
            return nil
        }
        filter.setValue(targetData, forKey: "inputMessage")

        guard let ciImage = filter.outputImage else {
            return nil
        }

        let size = UIScreen.main.bounds.size.width
        guard let img = createNonInterpolatedUIImage(from: ciImage, withSize: size) else {
            return nil
        }

        UIGraphicsBeginImageContext(img.size)
        defer { UIGraphicsEndImageContext() }
        img.draw(in: CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height))

        if let centerImg = logoImage {
            let centerW = img.size.width * 0.25
            let centerH = centerW
            let centerX = (img.size.width - centerW) / 2
            let centerY = (img.size.height - centerH) / 2
            centerImg.draw(in: CGRect(x: centerX, y: centerY, width: centerW, height: centerH))
        }

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
