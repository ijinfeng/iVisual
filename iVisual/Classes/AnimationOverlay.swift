//
//  AnimationOverlay.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/11.
//

import Foundation
import CoreMedia
import CoreImage
import UIKit

public class BaseAnimation {
    public fileprivate(set) var key: String?
    /// 相对于贴纸作用开始的时间，比如贴纸在2s中显示，`startTime`设置为1s，那么这个动画将在3s的时候生效
    public var startTime: CMTime = .zero
    /// 一个完整的动画持续时长
    public var duration: CMTime = .zero
    /// 在一个动画周期结束后，并且还未达到贴纸的结束时间，是否重复进行动画
    public var isRepeat: Bool = true
    /// 在一个动画周期结束后，并且还未达到贴纸的结束时间，是否自动按原路返回
    public var isAutoreverse: Bool = false
    
    public enum AnimationType {
        case none
        /// 透明度变化，类型为`CGFloat`
        case opacity
        /// 旋转变化，类型为`CGFloat`
        case rotate
        /// 缩放变化，类型为`CGFloat`
        case scale
        /// 位移变化，类型为`CGPoint`，相对于当前位置
        case translate
    }
    public var type: AnimationType = .none
}

extension BaseAnimation {
    func anyPointValue(_ value: Any?) -> CGPoint {
        if let value = value {
            if let ret = value as? CGPoint {
                return CGPoint(x: ret.x, y: ret.y)
            }
        }
        return .zero
    }
    
    func anyFloatValue(_ value: Any?) -> CGFloat {
        if let value = value {
            if let ret = value as? Double {
                return ret
            } else if let ret = value as? Int {
                return CGFloat(ret)
            }
        }
        return 0
    }
}

/// 基础动画
public class BasicAnimation: BaseAnimation {
    public var from: Any?
    public var to: Any?
}

/// 帧动画
public class KeyFrameAnimation: BaseAnimation {
    public var values: [Any] = []
    
    /// 当`keyTimes`设置为`nil`时，将会根据`values`自动做一个时间上的均分。keyTimes元素的取值范围是0~1
    public var keyTimes: [Float]?
}


/// 动画贴纸
public class AnimationOverlay: OverlayProvider {
    public var frame: CGRect = .zero {
        didSet {
            originFrame = frame
        }
    }
    public var timeRange: CMTimeRange = .zero
    public var bounds: CGRect {
        CGRect(origin: .zero, size: originFrame.size)
    }
    private var originFrame: CGRect = .zero
    
    public var extent: CGRect = .zero
    public var visualElementId: VisualElementIdentifer = .invalid
    public var userTransform: CGAffineTransform = .identity
    
    public var image: CIImage!
    
    private init() {}
    
    public init(image: CIImage) {
        self.image = image
        extent = image.extent
    }
    
    public func applyEffect(at time: CMTime) -> CIImage? {
        var _image: CIImage = image
        for (_, an) in animations {
            if an.type == .none { continue }
            
            var relativeTime = CMTimeSubtract(time, timeRange.start)
            let relativeSeconds = CMTimeGetSeconds(relativeTime)
            let duration = CMTimeGetSeconds(an.duration)
            
            // 第几个动画周期了
            var aci = 0
            if an.isRepeat {
                aci = Int(relativeSeconds / duration)
                relativeTime = CMTimeSubtract(relativeTime, CMTime.init(value: an.duration.value * Int64(aci), an.duration.timescale))
            }
            
            if an.isAutoreverse && aci % 2 == 1 {
                // 需要将动画反向
                relativeTime = CMTimeSubtract(an.duration, relativeTime)
            }
            
            if relativeTime >= an.startTime {
                // 达到触发动画的时机
                let progressTime = CMTimeSubtract(relativeTime, an.startTime)
                var progressRatio = CMTimeGetSeconds(progressTime) / duration
                if progressRatio > 1.0 {
                    progressRatio = 1.0
                }
                if an is BasicAnimation {
                    _image = handleAnimation(basic: an as! BasicAnimation, progress: progressRatio, image: _image)
                }
                else if an is KeyFrameAnimation {
                    _image = handleAnimation(keyframe: an as! KeyFrameAnimation, progress: progressRatio, image: _image)
                }
            }
        }
        return _image
    }
    
    private lazy var animations: [String?: BaseAnimation] = [:]
}

public extension AnimationOverlay {
    func add(animation an: BaseAnimation, for key: String?) {
        if an.duration == .zero {
            an.duration = timeRange.duration
        }
        guard an.duration > .zero else {
            return
        }
        guard an.startTime < timeRange.duration else {
            return
        }
        if an is BasicAnimation {
            let basic = an as! BasicAnimation
            guard basic.from != nil || basic.to != nil else {
                fatalError("BaseAnimation must set either fromValue or toValue")
            }
            switch basic.type {
            case .opacity:
                if basic.from == nil { basic.from = 1.0 }
                if basic.to == nil { basic.to = 1.0 }
            case .scale:
                if basic.from == nil { basic.from = 1.0 }
                if basic.to == nil { basic.to = 1.0 }
            case .rotate:
                if basic.from == nil { basic.from = 0 }
                if basic.to == nil { basic.to = nil }
            case .translate:
                if basic.from == nil { basic.from = CGPoint.zero }
                if basic.to == nil { basic.to = CGPoint.zero }
            default:
                break
            }
        } else if an is KeyFrameAnimation {
            let keyFrame = an as! KeyFrameAnimation
            guard !keyFrame.values.isEmpty else {
                return
            }
            if keyFrame.keyTimes == nil {
                var times: [Float] = []
                let averageTime = 1.0 / Float(keyFrame.values.count)
                var addTime = averageTime
                while times.count < keyFrame.values.count {
                    times.append(addTime)
                    addTime += averageTime
                }
                keyFrame.keyTimes = times
            }
        } else {
            fatalError("BaseAnimation is an abstract class and cannot be used directly")
        }
        an.key = key
        animations[key] = an
    }
    
    func remove(animation forkey: String?) {
        guard animations.has(key: forkey) else {
            return
        }
        animations.removeValue(forKey: forkey)
    }
}

private extension AnimationOverlay {
    func handleAnimation(basic an: BasicAnimation, progress ratio: CGFloat, image: CIImage) -> CIImage {
        guard an.from != nil && an.to != nil else {
            return image
        }
        switch an.type {
        case .opacity:
            let by = an.anyFloatValue(an.from) + (an.anyFloatValue(an.to) - an.anyFloatValue(an.from)) * ratio
            return image.apply(alpha: by)
        case .rotate:
            let by = an.anyFloatValue(an.from) + (an.anyFloatValue(an.to) - an.anyFloatValue(an.from)) * ratio
            return image.apply(rotate: by, extent: image.extent)
        case .scale:
            let by = an.anyFloatValue(an.from) + (an.anyFloatValue(an.to) - an.anyFloatValue(an.from)) * ratio
            return image.apply(scale: by, extent: image.extent)
        case .translate:
            let byx = an.anyPointValue(an.from).x + (an.anyPointValue(an.to).x - an.anyPointValue(an.from).x) * ratio
            let byy = an.anyPointValue(an.from).y + (an.anyPointValue(an.to).y - an.anyPointValue(an.from).y) * ratio
            let scalex: CGFloat = extent.width / frame.width
            let scaley: CGFloat = extent.height / frame.height
            return image.apply(translate: CGPoint(x: byx * scalex, y: -byy * scaley))
        default:
            break
        }
        return image
    }
    
    func handleAnimation(keyframe an: KeyFrameAnimation, progress ratio: CGFloat, image: CIImage) -> CIImage {
        guard !an.values.isEmpty else {
            return image
        }
        guard let keyTimes = an.keyTimes else {
            return image
        }
        // 计算当前进度对应的value和keyTime
        var keyTime: Float = Float(ratio)
        var index: Int = 0
        for i in 0..<keyTimes.count {
            let _keyTime = keyTimes[i]
            if keyTime <= _keyTime {
                keyTime = _keyTime
                index = i
                break
            }
        }
        let toValue = index >= an.values.count ? an.values.count - 1 : an.values[index]
        let fromValue: Any!
        if index == 0 {
            switch an.type {
            case .opacity:
                fromValue = 1.0
            case .scale:
                fromValue = 1.0
            case .rotate:
                fromValue = 0
            case .translate:
                fromValue = CGPoint.zero
            default:
                fromValue = 0
                break
            }
        } else {
            fromValue = an.values[index - 1]
        }
        
        // 转换成两个关键帧内的进度比
        var _ratio = ratio
        if index > 0 {
            let froKeyTime = keyTimes[index - 1]
            let curKeyDuration = keyTime - froKeyTime
            let relateTime = Float(_ratio) - froKeyTime
            _ratio = CGFloat(relateTime / curKeyDuration)
        } else {
            _ratio = _ratio / CGFloat(keyTime)
        }
//        print("keytime: \(keyTime), index: \(index), from: \(fromValue), to: \(toValue), ratio: \(_ratio)")
        
        switch an.type {
        case .opacity:
            let by = an.anyFloatValue(fromValue) + (an.anyFloatValue(toValue) - an.anyFloatValue(fromValue)) * _ratio
            return image.apply(alpha: by)
        case .rotate:
            let by = an.anyFloatValue(fromValue) + (an.anyFloatValue(toValue) - an.anyFloatValue(fromValue)) * _ratio
            return image.apply(rotate: by, extent: image.extent)
        case .scale:
            let by = an.anyFloatValue(fromValue) + (an.anyFloatValue(toValue) - an.anyFloatValue(fromValue)) * _ratio
            return image.apply(scale: by, extent: image.extent)
        case .translate:
            let byx = an.anyPointValue(fromValue).x + (an.anyPointValue(toValue).x - an.anyPointValue(fromValue).x) * _ratio
            let byy = an.anyPointValue(fromValue).y + (an.anyPointValue(toValue).y - an.anyPointValue(fromValue).y) * _ratio
            let scalex: CGFloat = extent.width / frame.width
            let scaley: CGFloat = extent.height / frame.height
            return image.apply(translate: CGPoint(x: byx * scalex, y: -byy * scaley))
        default:
            break
        }
        return image
    }
}
