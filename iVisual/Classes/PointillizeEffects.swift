//
//  PageCurlEffects.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/15.
//

import Foundation
import CoreMedia
import CoreImage
/// CIPointillize

public class PointillizeEffects: SpecialEffectsProvider {
    public var visualElementId: VisualElementIdentifer = .invalid
    public var timeRange: CMTimeRange = .zero
    
    private let filter: CIFilter!
    
    public init() {
        filter = CIFilter(name: "CIPointillize")
    }
    
    public func applyEffect(image: CIImage, at time: CMTime) -> CIImage? {
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(20.0, forKey: kCIInputRadiusKey)
        filter.setValue(CIVector(x: image.extent.center.x, y: image.extent.center.y), forKey: kCIInputCenterKey)
        return filter.outputImage
    }
}
