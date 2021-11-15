//
//  TimingProvider.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreMedia

public protocol TimingProvider {
    var timeRange: CMTimeRange { set get }
}
