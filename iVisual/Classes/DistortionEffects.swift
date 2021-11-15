//
//  DistortionEffects.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/12.
//

import Foundation
import CoreMedia
import CoreImage

/// 扭曲特效，基于`CIVortexDistortion`
public class DistortionEffects: SpecialEffectsProvider {
    public var visualElementId: VisualElementIdentifer = .invalid
    public var timeRange: CMTimeRange = .zero
    
    public var maxAngle: CGFloat = 360.0
    public var radius: CGFloat = 1800
    
    private let filter: CIFilter!
    
    public init() {
        filter = CIFilter(name: "CIVortexDistortion")
        
    }
    
    public func applyEffect(image: CIImage, at time: CMTime) -> CIImage? {
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: image.extent.center.x, y: image.extent.center.y), forKey: kCIInputCenterKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        let relateTime = CMTimeSubtract(time, timeRange.start)
        let ratio = CMTimeGetSeconds(relateTime) / CMTimeGetSeconds(timeRange.duration)
        filter.setValue(ratio * maxAngle, forKey: kCIInputAngleKey)
        return filter.outputImage
    }
}
