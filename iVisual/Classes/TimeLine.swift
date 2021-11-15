//
//  TimeLine.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import UIKit
import AVFoundation

public class TimeLine {
    public let asset: AVAsset!
    
    public init(asset: AVAsset) {
        self.asset = asset
    }
    
    public var renderSize: CGSize = CGSize(width: 960, height: 540)
    public var renderScale: Float = 1.0
    public var frameDuration: CMTime = CMTime.init(value: 1, timescale: 30)
    
    
    public enum ContentMode {
        case scaleAspectFit
        case scaleAspectFill
        case scaleFill
    }
    public var contentMode: ContentMode = .scaleAspectFit
    public var backgroundColor: UIColor?
    /// 当前播放到那一帧的时间
    public private(set) var currentTime: CMTime = .zero
    
    private var eidBuilder = ElementIdentiferBuilder()
    private var overlayElementDic: [VisualElementIdentifer: OverlayProvider] = [:]
    private var specialEffectsElementDic: [VisualElementIdentifer: SpecialEffectsProvider] = [:]
}

// MARK: Public API
public extension TimeLine {
    @discardableResult func insert(element: OverlayProvider) -> VisualElementIdentifer {
        let id = eidBuilder.get()
        element.visualElementId = id
        overlayElementDic[id] = element
        return id
    }
    
    @discardableResult func insert(element: SpecialEffectsProvider) -> VisualElementIdentifer {
        let id = eidBuilder.get()
        element.visualElementId = id
        specialEffectsElementDic[id] = element
        return id
    }
    
    func removed(element useId: VisualElementIdentifer) {
        if overlayElementDic.has(key: useId) {
            overlayElementDic.removeValue(forKey: useId)
        }
        if specialEffectsElementDic.has(key: useId) {
            specialEffectsElementDic.removeValue(forKey: useId)
        }
    }
}

extension TimeLine {
    func apply(source: CIImage, at time: CMTime) -> CIImage {
        currentTime = time
        
        var image = source
        
        // 修改视频布局显示 `contentMode`
        let t: CGAffineTransform!
        let renderRect = CGRect(origin: .zero, size: renderSize)
        switch contentMode {
        case .scaleAspectFit:
            t = CGAffineTransform.transform(rect: image.extent, aspectFit: renderRect)
        case .scaleFill:
            t = CGAffineTransform.transform(rect: image.extent, fill: renderRect)
        case .scaleAspectFill:
            t = CGAffineTransform.transform(rect: image.extent, aspectFill: renderRect)
        }
        image = image.transformed(by: t)
        if contentMode == .scaleAspectFill {
            image = image.cropped(to: renderRect)
        }
        
        // 处理贴纸
        overlayElementDic.values.forEach { provider in
            if CMTimeRangeContainsTime(provider.timeRange, time: time) {
                if var effectImage = provider.applyEffect(at: time) {
                    // 图片一旦旋转，那么，它的extent会发生改变，但是图片的bounds是不变的
                    let bounds = provider.extent
                    // 转换坐标系，默认原点在左下角
                    var fillRect = bounds.fill(to: provider.frame)
                    fillRect.origin = provider.frame.origin
                    // 这段代码的目的就是将左下角的图片移动到正确的位置，并且缩放到正常比例
                    let screenScale = image.extent.width / UIScreen.main.bounds.width
                    fillRect = fillRect.scale(by: screenScale)
                    let yratio = fillRect.height / bounds.height
                    let xratio = fillRect.width / bounds.width
                    let t = CGAffineTransform.transform(rect: bounds, fill: provider.frame.scale(by: screenScale)).translatedBy(x: fillRect.origin.x / xratio, y: (renderRect.height - fillRect.height - fillRect.origin.y) / yratio)
                    effectImage = effectImage.transformed(by: t)
                    image = effectImage.composited(over: image)
                }
            }
        }
        
        specialEffectsElementDic.values.forEach { provider in
            if CMTimeRangeContainsTime(provider.timeRange, time: time) {
                if let effectImage = provider.applyEffect(image: image, at: time) {
                    image = effectImage
                }
            }
        }
        
        return image
    }
}
