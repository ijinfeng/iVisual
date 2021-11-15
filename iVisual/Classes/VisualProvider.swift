//
//  VisualProvider.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreMedia
import CoreImage

public typealias VisualElementIdentifer = Int32
extension VisualElementIdentifer {
    public static let invalid: VisualElementIdentifer = 0
}

public protocol VisualProvider: AnyObject, TimingProvider {
    /// `id` 由框架自动生成，一般不需要手动设置
    var visualElementId: VisualElementIdentifer { set get }
}
