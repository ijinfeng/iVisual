//
//  VideoCompositionBuilder.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import AVFoundation

public class VideoCompositionBuilder {
    public let outVideoComposition: AVVideoComposition?
    public let timeLine: TimeLine!
    
    public init(exist videoComposition: AVVideoComposition? = nil, timeLine: TimeLine) {
        outVideoComposition = videoComposition
        self.timeLine = timeLine
        let c = CompositionCoordinator(timeLine: timeLine)
        CompositionCoordinatorPool.shared.add(coordinator: c)
    }
    
    private init() {
        fatalError("use `init(exist videoComposition: AVVideoComposition? = nil, timeLine: TimeLine)` to initialize")
    }
}

// MARK: Public API
public extension VideoCompositionBuilder {
    func buildVideoCompositon() -> AVVideoComposition {
        let videoComposition = (outVideoComposition?.mutableCopy() as? AVMutableVideoComposition) ?? AVMutableVideoComposition(propertiesOf: timeLine.asset)
        videoComposition.renderSize = timeLine.renderSize
        videoComposition.renderScale = timeLine.renderScale
        videoComposition.frameDuration = timeLine.frameDuration
        videoComposition.customVideoCompositorClass = VideoCustomComposition.self
        
        return videoComposition
    }
}
