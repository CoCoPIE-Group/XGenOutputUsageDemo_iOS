//
//  RGBAImage.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/30.
//

import UIKit

public struct Pixel {
    public var value: UInt32
    
    //red
    public var R: UInt8 {
        get { return UInt8(value & 0xFF); }
        set { value = UInt32(newValue) | (value & 0xFFFFFF00) }
    }
    
    //green
    public var G: UInt8 {
        get { return UInt8((value >> 8) & 0xFF) }
        set { value = (UInt32(newValue) << 8) | (value & 0xFFFF00FF) }
    }
    
    //blue
    public var B: UInt8 {
        get { return UInt8((value >> 16) & 0xFF) }
        set { value = (UInt32(newValue) << 16) | (value & 0xFF00FFFF) }
    }
    
    //alpha
    public var A: UInt8 {
        get { return UInt8((value >> 24) & 0xFF) }
        set { value = (UInt32(newValue) << 24) | (value & 0x00FFFFFF) }
    }
}

public struct RGBAImage {
    public var pixels: UnsafeMutableBufferPointer<Pixel>
    public var width: Int
    public var height: Int
    
    public init?(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        width = Int(image.size.width)
        height = Int(image.size.height)
        
        let bytesPerRow = width * 4
        let imageData = UnsafeMutablePointer<Pixel>.allocate(capacity: width * height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // BGRA
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        bitmapInfo = bitmapInfo | CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        guard let imageContext = CGContext(data: imageData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        imageContext.draw(cgImage, in: CGRect(origin: .zero, size: image.size))
        
        pixels = UnsafeMutableBufferPointer<Pixel>(start: imageData, count: width * height)
    }
    

    public init(width: Int, height: Int) {
        let image = RGBAImage.newUIImage(width: width, height: height)
        self.init(image: image)!
    }
    
    public func toUIImage() -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue
        let bytesPerRow = width * 4
        
        bitmapInfo |= CGImageAlphaInfo.premultipliedLast.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        guard let imageContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil) else {
            return nil
        }
        
        guard let cgImage = imageContext.makeImage() else {
            return nil
        }
        
        let image = UIImage(cgImage: cgImage)
        return image
    }

    
    public func pixel(x : Int, _ y : Int) -> Pixel? {
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return nil
        }
        
        let address = y * width + x
        return pixels[address]
    }
    
    public mutating func pixel(x : Int, _ y : Int, _ pixel: Pixel) {
        guard x >= 0 && x < width && y >= 0 && y < height else {
            return
        }
        
        let address = y * width + x
        pixels[address] = pixel
    }
    
    public mutating func process(functor : ((Pixel) -> Pixel) ) {
        for y in 0..<height {
            for x in 0..<width {
                let index = y * width + x
                let outPixel = functor(pixels[index])
                pixels[index] = outPixel
            }
        }
    }
    
    private static func newUIImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: CGFloat(width), height: CGFloat(height));
        UIGraphicsBeginImageContextWithOptions(size, true, 0);
        UIColor.black.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image!
    }
}

extension RGBAImage {
     public static func composite(_ rgbaImageList: RGBAImage...) -> RGBAImage {
        let result : RGBAImage = RGBAImage(width:rgbaImageList[0].width, height: rgbaImageList[0].height)
        for y in 0..<result.height {
            for x in 0..<result.width {
                
                let index = y * result.width + x
                var pixel = result.pixels[index]
                
                for rgba in rgbaImageList {
                    let rgbaPixel = rgba.pixels[index]
                    pixel.R = min(pixel.R + rgbaPixel.R, 255)
                    pixel.G = min(pixel.G + rgbaPixel.G, 255)
                    pixel.B = min(pixel.B + rgbaPixel.B, 255)
                }
                
                result.pixels[index] = pixel
            }
        }
        return result
    }
}

