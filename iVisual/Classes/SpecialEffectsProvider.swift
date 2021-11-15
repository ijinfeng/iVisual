//
//  SpecialEffectsProvider.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreImage
import CoreMedia

public protocol SpecialEffectsProvider: VisualProvider {
    func applyEffect(image: CIImage, at time: CMTime) -> CIImage?
}
