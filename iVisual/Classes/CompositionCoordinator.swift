//
//  CompositionCoordinator.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreImage
import CoreMedia

struct CompositionCoordinator {
    let timeLine: TimeLine
    
    func apply(source: CIImage, at time: CMTime) -> CIImage {
        return timeLine.apply(source: source, at: time)
    }
    
    func needRenderAgain() {
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "哈哈哈"), object: nil)
    }
}


class CompositionCoordinatorPool {
    static let shared = CompositionCoordinatorPool()
    
    private var coordinator: CompositionCoordinator?
    
    func pop() -> CompositionCoordinator? {
        coordinator
    }
    
    func add(coordinator: CompositionCoordinator) {
        self.coordinator = coordinator
    }
    
    private init() {}
}

