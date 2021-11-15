//
//  CGExtensions.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreGraphics

extension CGAffineTransform {
    
    /// 获取旋转的角度
    /// - Returns: 角度: 0, 90, 180, 270
    func getTransformAngle() -> CGFloat {
        var angle: CGFloat = 0
        if a == 0 && b == 1 && c == -1 && d == 0 {
            angle = 90
        } else if a == 0 && b == -1 && c == 1 && d == 0 {
            angle = 270
        } else if a == 1 && b == 0 && c == 0 && d == 1 {
            angle = 0
        } else if a == -1 && b == 0 && c == 0 && d == -1 {
            angle = 180
        } else {
            // other angle
        }
        return angle
    }
    
    /// 是否倾倒
    /// - Returns: 返回`true`表示倾倒
    func isTopple() -> Bool {
        let t = getTransformAngle()
        if t == 90 || t == 270 {
            return true
        }
        return false
    }
    
    /// 通过给定的原始`rect`，将其适配到容器`rect`中后，返回仿射矩阵
    /// - Parameters:
    ///   - rect: 原始`rect`
    ///   - toRect: 容器`rect`
    /// - Returns: 仿射矩阵
    static func transform(rect: CGRect, aspectFit toRect: CGRect) -> CGAffineTransform {
        let _rect = rect.aspectFit(to: toRect)
        let xRatio = _rect.size.width / rect.size.width
        let yRatio = _rect.size.height / rect.size.height
        return CGAffineTransform(translationX: _rect.origin.x - rect.origin.x * xRatio, y: _rect.origin.y - rect.origin.y * yRatio).scaledBy(x: xRatio, y: yRatio)
    }
    
    static func transform(rect: CGRect, aspectFill toRect: CGRect) -> CGAffineTransform {
        let _rect = rect.aspectFill(to: toRect)
        let xRatio = _rect.size.width / rect.size.width
        let yRatio = _rect.size.height / rect.size.height
        let mx = _rect.origin.x - rect.origin.x * xRatio
        let my = _rect.origin.y - rect.origin.y * yRatio
        return CGAffineTransform(translationX: mx, y: my).scaledBy(x: xRatio, y: yRatio)
    }
    
    static func transform(rect: CGRect, fill toRect: CGRect) -> CGAffineTransform {
        let _rect = rect.fill(to: toRect)
        let xRatio = _rect.size.width / rect.size.width
        let yRatio = _rect.size.height / rect.size.height
        return CGAffineTransform(scaleX: xRatio, y: yRatio)
    }
}


extension CGRect {
    func aspectFit(to rect: CGRect) -> CGRect {
        let _size = size.aspectFit(in: rect.size)
        let x = (rect.size.width - _size.width) / 2
        let y = (rect.size.height - _size.height) / 2
        return CGRect(origin: CGPoint(x: x, y: y), size: _size)
    }
    
    func fill(to rect: CGRect) -> CGRect {
        let _size = size.fill(to: rect.size)
        return CGRect(origin: rect.origin, size: _size)
    }
    
    func aspectFill(to rect: CGRect) -> CGRect {
        let _size = size.aspectFill(to: rect.size)
        let x = (rect.size.width - _size.width) / 2
        let y = (rect.size.height - _size.height) / 2
        return CGRect(origin: CGPoint(x: x, y: y), size: _size)
    }
    
    func scale(by ratio: CGFloat) -> CGRect {
        scale(by: ratio, yRatio: ratio)
    }
    
    func scale(by xRatio: CGFloat, yRatio: CGFloat) -> CGRect {
        CGRect(x: origin.x * xRatio, y: origin.y * yRatio, width: size.width * xRatio, height: size.height * yRatio)
    }
}


extension CGSize {
    
    /// 将当前`size`适配到给定的容器内
    /// - Parameter size: 容器大小
    /// - Returns: 适配后的大小
    func aspectFit(to size: CGSize) -> CGSize {
        var fitSize: CGSize!
        let oRatio = width / height
        let tRatio = size.width / height
        if oRatio > tRatio {
            fitSize = CGSize(width: size.width, height: size.width / width * height)
        } else {
            fitSize = CGSize(width: size.height / height * width, height: size.height)
        }
        return fitSize
    }
    
    /// 将当前`size`铺满给定的容器内
    /// - Parameter size: 容器大小
    /// - Returns: 适配后的大小
    func fill(to size: CGSize) -> CGSize {
        size
    }
    
    /// 将当前`size`适配并铺满到给定的容器内
    /// - Parameter size: 容器大小
    /// - Returns: 适配后的大小
    func aspectFill(to size: CGSize) -> CGSize {
        var fitSize: CGSize!
        let oRatio = width / height
        let tRatio = size.width / height
        if oRatio > tRatio {
            fitSize = CGSize(width: size.height / height * width, height: size.height)
        } else {
            fitSize = CGSize(width: size.width, height: size.width / width * height)
        }
        return fitSize
    }
}
