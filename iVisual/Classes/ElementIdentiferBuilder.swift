//
//  ElementIdentiferBuilder.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation

public struct ElementIdentiferBuilder {
    private var eid: VisualElementIdentifer = .invalid
    
    public mutating func `get`() -> VisualElementIdentifer {
        eid += 1
        return eid
    }
    
    public mutating func reset() {
        eid = .invalid
    }
}
