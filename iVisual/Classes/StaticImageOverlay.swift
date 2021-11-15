//
//  StaticImageOverlay.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreMedia
import CoreImage
import UIKit

/// 静态图片贴纸
public class StaticImageOverlay: OverlayProvider {
    public var frame: CGRect = .zero
    public var timeRange: CMTimeRange = .zero
    
    public var extent: CGRect = .zero
    public var visualElementId: VisualElementIdentifer = .invalid
    public var userTransform: CGAffineTransform = .identity
    
    public var image: CIImage!
    
    public func applyEffect(at time: CMTime) -> CIImage? {
        image
    }
    
    public init(image: CIImage) {
        self.image = image
        frame = CGRect(origin: .zero, size: image.extent.size)
        extent = image.extent
    }
    
    private init() {}
    
}

