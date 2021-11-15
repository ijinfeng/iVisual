//
//  CMExtensions.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreMedia

extension CMTimeRange {
    
    /// 返回结束时间
    public var end: CMTime {
        CMTimeAdd(start, duration)
    }

}
