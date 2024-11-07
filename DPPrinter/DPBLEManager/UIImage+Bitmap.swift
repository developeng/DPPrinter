//
//  UIImage+Bitmap.swift
//  DPPrinter
//
//  Created by developeng on 2024/11/6.
//
import UIKit
import AVFoundation

// 将图片转为位图
extension UIImage {
    
    private static let redPixel: CGFloat = 0.299
    private static let greenPixel: CGFloat = 0.587
    private static let bluePixel: CGFloat = 0.114
    
    // MARK: - Bitmap Data
    
    func bitmapData() -> Data? {
        guard let cgImage = cgImage else {
            return nil
        }

        // Create a bitmap context to draw the image into
        guard let context = bitmapRGBContext() else {
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height
        let rect = CGRect(x: 0, y: 0, width: width, height: height)

        // Draw image into the context to get the raw image data
        context.draw(cgImage, in: rect)

        // Get a pointer to the data
        guard let bitmapData = context.data?.assumingMemoryBound(to: UInt32.self) else {
            return nil
        }

        var imageData = [UInt8](repeating: 0, count: width * height / 8 + 8 * height / 8)
        var resultIndex = 0

        var newY = 0
        while newY < height {
            imageData[resultIndex] = 27
            imageData[resultIndex + 1] = 51
            imageData[resultIndex + 2] = 0
            imageData[resultIndex + 3] = 27
            imageData[resultIndex + 4] = 42
            imageData[resultIndex + 5] = 33
            imageData[resultIndex + 6] = UInt8(width % 256)
            imageData[resultIndex + 7] = UInt8(width / 256)
            resultIndex += 8

            for x in 0..<width {
                var value = 0
                for tempY in 0..<8 {
                    let rgbaPixel = bitmapData.advanced(by: (newY + tempY) * width + x)
                    let gray = UIImage.redPixel * CGFloat((rgbaPixel.pointee >> 16) & 0xFF) +
                    UIImage.greenPixel * CGFloat((rgbaPixel.pointee >> 8) & 0xFF) +
                    UIImage.bluePixel * CGFloat(rgbaPixel.pointee & 0xFF)

                    if gray < 127 {
                        value += 1 << (7 - tempY) & 255
                    }
                }
                imageData[resultIndex] = UInt8(value)
                resultIndex += 1

                value = 0
                for tempY in 8..<16 {
                    let rgbaPixel = bitmapData.advanced(by: (newY + tempY) * width + x)
                    let gray = UIImage.redPixel * CGFloat((rgbaPixel.pointee >> 16) & 0xFF) +
                    UIImage.greenPixel * CGFloat((rgbaPixel.pointee >> 8) & 0xFF) +
                    UIImage.bluePixel * CGFloat(rgbaPixel.pointee & 0xFF)

                    if gray < 127 {
                        value += 1 << (7 - tempY % 8) & 255
                    }
                }
                imageData[resultIndex] = UInt8(value)
                resultIndex += 1

                value = 0
                for tempY in 16..<24 {
                    let rgbaPixel = bitmapData.advanced(by: (newY + tempY) * width + x)
                    let gray = UIImage.redPixel * CGFloat((rgbaPixel.pointee >> 16) & 0xFF) +
                    UIImage.greenPixel * CGFloat((rgbaPixel.pointee >> 8) & 0xFF) +
                    UIImage.bluePixel * CGFloat(rgbaPixel.pointee & 0xFF)

                    if gray < 127 {
                        value += 1 << (7 - tempY % 8) & 255
                    }
                }
                imageData[resultIndex] = UInt8(value)
                resultIndex += 1
            }

            imageData[resultIndex] = 13
            imageData[resultIndex + 1] = 10
            resultIndex += 2
            newY += 24
        }

        return Data(bytes: imageData, count: resultIndex)
    }
    
    func bitmapRGBContext() -> CGContext? {
        guard let cgImage = cgImage else {
            return nil
        }
        
        var context: CGContext?
        var colorSpace: CGColorSpace?
        var bitmapData: UnsafeMutablePointer<UInt32>?
        
        let bitsPerPixel = 32
        let bitsPerComponent = 8
        let bytesPerPixel = bitsPerPixel / bitsPerComponent
        
        let width = cgImage.width
        let height = cgImage.height
        
        let bytesPerRow = width * bytesPerPixel
        let bufferLength = bytesPerRow * height
        
        colorSpace = CGColorSpaceCreateDeviceRGB()
        
        if colorSpace == nil {
            print("Error allocating color space RGB")
            return nil
        }
        
        // Allocate memory for image data
        bitmapData = UnsafeMutablePointer<UInt32>.allocate(capacity: bufferLength)
        
        if bitmapData == nil {
            print("Error allocating memory for bitmap")
            return nil
        }
        
        // Create bitmap context
        context = CGContext(data: bitmapData,
                            width: width,
                            height: height,
                            bitsPerComponent: bitsPerComponent,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        if context == nil {
            bitmapData?.deallocate()
            print("Bitmap context not created")
        }
        
        return context
    }
    
    
    // MARK: - Scaled Image
    func imageWithScale(maxWidth: CGFloat, quality: CGFloat) -> UIImage? {
        // 确保打印图片宽度为 24 的倍数，高度向上兼容
        let newWidth = floor(maxWidth / 24.0) * 24
        // 图片打印丢失部分是高度不足 24 的倍数造成的，此处转化图片高度为 24 的倍数
        let newHeight = newWidth * size.height / size.width
        let adjustedHeight = ceil(newHeight / 24) * 24
        
        let size = CGSize(width: newWidth, height: adjustedHeight)
        
        UIGraphicsBeginImageContext(size)
        defer {
            UIGraphicsEndImageContext()
        }
        
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: adjustedHeight))
        
        guard let resultImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        // 设置你想要的压缩质量，范围从 0.0 到 1.0
        guard let imageData = resultImage.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
}


