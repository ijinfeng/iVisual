//
//  CIExtensions.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/11.
//

import Foundation
import CoreImage
import UIKit

extension CIImage {
    /// 设置图片的透明度
    /// https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/filter/ci/CIColorMatrix
    /// - Parameter alpha: 透明度的值`0 ~ 1`
    /// - Returns: 透明度图片
    func apply(alpha: CGFloat) -> CIImage {
        return apply(red: nil, green: nil, blue: nil, alpha: alpha)
    }
    
    func apply(red: CGFloat, green: CGFloat, blue: CGFloat) -> CIImage {
        return apply(red: red, green: green, blue: blue, alpha: nil)
    }
    
    func apply(red: CGFloat?, green: CGFloat?, blue: CGFloat?, alpha: CGFloat?) -> CIImage {
        let filter = CIFilter(name: "CIColorMatrix")
        filter?.setDefaults()
        filter?.setValue(self, forKey: kCIInputImageKey)
        if let red = red {
            let vector = CIVector.init(x: red, y: 0, z: 0, w: 0)
            filter?.setValue(vector, forKey: "inputRVector")
        }
        if let green = green {
            let vector = CIVector.init(x: 0, y: green, z: 0, w: 0)
            filter?.setValue(vector, forKey: "inputGVector")
        }
        if let blue = blue {
            let vector = CIVector.init(x: 0, y: 0, z: blue, w: 0)
            filter?.setValue(vector, forKey: "inputBVector")
        }
        if let alpha = alpha {
            let vector = CIVector.init(x: 0, y: 0, z: 0, w: alpha)
            filter?.setValue(vector, forKey: "inputAVector")
        }
        if let outputImage = filter?.outputImage {
            return outputImage
        }
        return self
    }
    
    
    /// 旋转图片
    /// - Parameter rotate: 弧度
    /// - Parameter extent: 图片的真实尺寸：`CIImage.extent`
    /// - Returns: 返回旋转之后的图片
    func apply(rotate: CGFloat, extent: CGRect) -> CIImage {
        var t = CGAffineTransform.identity
        t = t.concatenating(CGAffineTransform(translationX: -(extent.origin.x + extent.width/2), y: -(extent.origin.y + extent.height/2)))
        t = t.concatenating(CGAffineTransform.init(rotationAngle: rotate))
        t = t.concatenating(CGAffineTransform(translationX: (extent.origin.x + extent.width/2), y: (extent.origin.y + extent.height/2)))
        return transformed(by: t)
    }
    
    func apply(scale: CGFloat, extent: CGRect) -> CIImage {
        var t = CGAffineTransform.identity
        t = t.concatenating(CGAffineTransform(translationX: -(extent.origin.x + extent.width/2), y: -(extent.origin.y + extent.height/2)))
        t = t.concatenating(CGAffineTransform.init(scaleX: scale, y: scale))
        t = t.concatenating(CGAffineTransform(translationX: (extent.origin.x + extent.width/2), y: (extent.origin.y + extent.height/2)))
        return transformed(by: t)
    }
    
    func apply(translate: CGPoint) -> CIImage {
        let t = CGAffineTransform.init(translationX: translate.x, y: translate.y)
        let image = transformed(by: t)
        return image
    }
}
