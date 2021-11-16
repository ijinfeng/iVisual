

# 基于自定义AVVideoComposition的视频贴纸和特效实现

有过 `AVFoundation` 框架开发经验的同学应该听说过 `AVVideoComposition` 这个类，它的功能非常强大，我们可以通过它实现诸如贴纸，视频特效，转场等功能，基本上你在短视频编辑程序上看到的功能，都能通过它来实现。

这篇文章主要将视频贴纸和特效是如何实现的。所有功能都是基于 `AVFoundation` 框架实现。

如果你要实现贴纸功能，有两种方案：

1、基于 `AVVideoComposition` 的 `AVVideoCompositionCoreAnimationTool` 接口，原理就是在视频播放层上添加贴纸层，并通过 `AVSynchronizedLayer` 来管理贴纸基于播放时间的显示状态。

2、遵循 `AVVideoCompositing` 协议，自定义视频合成器。 

这上面的方法1不能用于实现视频画面的特效，因为他们分属于不同层级，你只能管理贴纸层。而方法2则能实现贴纸和特效功能。本文也是基于第二种方式来讲解这部分功能的实现。

# 一、原理

如果要给视频添加贴图或者是特效，那么我们是不是得先拿到展示的那一帧画面，这样我们就可以将我们的贴纸添加上去，或者将这一帧画面处理成特效之后再给视频合成框架进行渲染展示。现在摆在我们眼前的就是如何能拿到这一帧画面呢🤔？

`AVVideoComposition` 里面有个 `customVideoCompositorClass` 属性，它要求我们传入遵循 `AVVideoCompositing` 协议的类型进去（注：不是实例），里面有个方法 `func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest)` ，表示开始一个合成请求，我们就在这个函数下完成原视频画面和贴纸画面的合成，或者是将这一帧画面处理成特效，并在处理完成之后调用`finish`函数提交这一帧合成后的画面。这个 `startRequest`  函数会被多次调用，和当前展示的画面同步，直到暂停播放。

# 二、为 AVPlayerItem 添加 AVVideoComposition

`AVVideoComposition` 的实例可以作为 `AVPlayerItem` 的一个属性传入，这样当 `AVPlayerItem` 在播放的时候就会使用我们传入的 `AVVideoComposition` 来处理每一帧画面了。使用起来就像下面这个样子。

```swift
let videoCompostion = AVMutableVideoComposition(propertiesOf: asset)
videoComposition.renderSize = CGSize(width: 1920, height: 1080)
playerItem.videoComposition = videoCompostion
player = AVPlayer.init(playerItem: playerItem)
```

# 三、自定义AVVideoCompositing

现在，我们已经创建了一个 `AVMutableVideoComposition` 实例了，那么我们如何接管每一帧画面？那就是自定义 `AVVideoCompositing`。`AVVideoComposition` 有个属性叫 `customVideoCompositorClass` ，类型为 `AVVideoCompositing.Type?`。通过它，我们能获取到视频播放时展示的每一帧原始画面信息。下面是协议`AVVideoCompositing`的部分信息。

```swift
public class VideoCustomComposition: NSObject, AVVideoCompositing {
      public var sourcePixelBufferAttributes: [String : Any]? = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                        String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    public var requiredPixelBufferAttributesForRenderContext: [String : Any] = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                                                         String(kCVPixelBufferOpenGLESCompatibilityKey): true]

        public func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderQueue.sync { [weak self] in
            self?.renderContext = newRenderContext
        }
    }
    
    public func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
                // 合成逻辑
        }

}
```

上面这些是 `required` 的，我们主要关注 `startRequest` 方法的实现。当播放器播放到下一帧画面但还没展示的时候，会调用这个方法来告诉开发者有新的画面需要被显示，如何处理。而所有信息都包含在 `asyncVideoCompositionRequest` 中。进入 `AVAsynchronousVideoCompositionRequest` 类查看，里面主要有下面这些属性和方法：

```swift
// 渲染上下文
open var renderContext: AVVideoCompositionRenderContext { get }

// 合成时间，和帧率有关，可以理解成每一帧画面的显示时间
open var compositionTime: CMTime { get }

// 视频通道id
open var sourceTrackIDs: [NSNumber] { get }

// 合成指令，可以自定义，默认是系统提供的 AVVideoCompositionInstruction 类
open var videoCompositionInstruction: AVVideoCompositionInstructionProtocol { get }

// 返回指定trackID下的视频帧的像素级信息，和当前的播放时间同步
open func sourceFrame(byTrackID trackID: CMPersistentTrackID) -> CVPixelBuffer?

// 提交处理完的像素信息
open func finish(withComposedVideoFrame composedVideoFrame: CVPixelBuffer)

// 提交此次合成操作，并设置错误，表示合成失败
open func finish(with error: Error)

// 请求被取消
open func finishCancelledRequest()
```

接下来看下`startRequest`方法的实现

```swift
public func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        renderQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.shouldCancelAllPendingRequests {
                asyncVideoCompositionRequest.finishCancelledRequest()
            } else {
                autoreleasepool {
// 处理合成请求，并返回处理后的数据
                    if let pixelBuffer = strongSelf.handleNewPixelBuffer(from: asyncVideoCompositionRequest) {
                        asyncVideoCompositionRequest.finish(withComposedVideoFrame: pixelBuffer)
                    } else {
// 合成失败，返回错误
                        asyncVideoCompositionRequest.finish(with: VideoCustomCompositionError.newPixelBufferRequestFailed)
                    }
                }
            }
        }
    }
```

处理合并请求的具体逻辑，每段代码我加了注视，还是比较清楚的。

```swift
func handleNewPixelBuffer(from request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
        // 创建一块空白的画布
        guard let pixelBuffer = request.renderContext.newPixelBuffer() else {
            return nil
        }
    
        // 画布的大小为 VideoComposition 的 renderSize
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var image: CIImage?
        
// 设置默认的背景色
        var backgroundColor: CGColor = UIColor.black.cgColor
        if let instruction =  request.videoCompositionInstruction as? AVVideoCompositionInstruction {
            backgroundColor = instruction.backgroundColor ?? UIColor.black.cgColor
        }
// 设置自定义的背景色
        if let coordinator = coordinator {
            if let timeLineBackgroundColor = coordinator.timeLine.backgroundColor {
                backgroundColor = timeLineBackgroundColor.cgColor
            }
        }
        
        // 填充背景色
        let backgroundImage = CIImage(color: CIColor(cgColor: backgroundColor)).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
        
        // 真实的视频帧画面
        for trackID in request.sourceTrackIDs {
            if let sourcePixelBuffer = request.sourceFrame(byTrackID: trackID.int32Value) {
                let sourceImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
                image = sourceImage
            }
        }
        
        // 当没有视频画面的时候，返回默认背景色
        guard var videoImage = image else {
            VideoCustomComposition.ciContext.render(backgroundImage, to: pixelBuffer)
            return pixelBuffer
        }
        
        // 外部处理这帧画面，做贴纸或特效处理
        if let coordinator = coordinator {
            videoImage = coordinator.apply(source: videoImage, at: request.compositionTime)
        }
        
// 将处理后的视频帧合并到背景图上
        videoImage = videoImage.composited(over: backgroundImage)
        
        // 将最终画面输出到像素缓冲区
        VideoCustomComposition.ciContext.render(videoImage, to: pixelBuffer)
        
        return pixelBuffer
    }
```

这里我们看到一个属性 `coordinator` ，它是`VideoCustomComposition`的一个属性 `private var coordinator: CompositionCoordinator? = CompositionCoordinatorPool.shared.pop()` 表示协调器。这里又要引出一个类，叫 `TimeLine`。而`coordinator` 就是用来协调`VideoCustomComposition`和`TimeLine`的数据交互问题。`apply`方法也只是简单的做了一个透传。

```swift
struct CompositionCoordinator {
    let timeLine: TimeLine
    
    func apply(source: CIImage, at time: CMTime) -> CIImage {
        return timeLine.apply(source: source, at: time)
    }
}
```

# 四、添加贴纸和特效

在第三步中，我们已经成功拿到了视频播放的每一帧画面，并将它传递给了`TimeLine`类来处理。`TimeLine`是一个表示视频播放完整时间轴的一个类，我们可以在上面添加贴纸，也可以设置某个时间段内的视频的显示特效。

## 一、贴纸

```swift
@discardableResult func insert(element: OverlayProvider) -> VisualElementIdentifer {
        let id = eidBuilder.get()
        element.visualElementId = id
        overlayElementDic[id] = element
        return id
    }
```

`TimeLine`里的贴纸是一个遵循协议`OverlayProvider`的类，协议要求贴纸必须实现：贴纸位置 `frame`、贴纸原始大小`extent`、在某一时刻的展示图片`func applyEffect(at time: CMTime) -> CIImage?`。`OverlayProvider`协议继承于`VisualProvider`协议，该协议要求提供一个`id`，类型为`VisualElementIdentifer`，这个`id`在`TimeLine`内部会自动设置，因此设置为默认的`invalid`就好。而`VisualProvider`协议则又继承于`TimingProvider`协议，该协议要求提供一个`CMTimeRange`类型的`timeRange`，表示在视频的那一段时间范围内有效。

我们看一个实现好的静态贴纸的例子：

```swift
/// 静态图片贴纸
public class StaticImageOverlay: OverlayProvider {
    public var frame: CGRect = .zero
    public var timeRange: CMTimeRange = .zero
    
    public var extent: CGRect = .zero
    public var visualElementId: VisualElementIdentifer = .invalid
    
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
```

使用起来也很简单，如下就往当前的视频的时间轴的第0s到2s的范围插入了一个静态贴纸。

```swift
let uiimage = UIImage(named: "biaozhun")!
            let ciimage = CIImage(cgImage: uiimage.cgImage!)
            let overlay = StaticImageOverlay.init(image: ciimage)
            overlay.timeRange = CMTimeRange.init(start: CMTime.init(value: 0, timescale: 1), end: CMTime.init(value: 2, timescale: 1))
            overlay.frame = CGRect(x: 20, y: 20, width: 160, height: 60)
timeLine.insert(element: overlay)
        let videoCompostion = builder.buildVideoCompositon()
        playerItem.videoComposition = videoCompostion
        player.replaceCurrentItem(with: playerItem)
```

![animate.gif](%E5%9F%BA%E4%BA%8E%E8%87%AA%E5%AE%9A%E4%B9%89AVVideoComposition%E7%9A%84%E8%A7%86%E9%A2%91%E8%B4%B4%E7%BA%B8%E5%92%8C%E7%89%B9%E6%95%88%E5%AE%9E%E7%8E%B0%20b9b65a0f19e84652b71be8d985025660/animate.gif)

而动态贴纸的原理其实和静态贴纸的原理是一样的，只不过多了解析gif图的过程。我们需要把gif的每一帧读取出来，得到他们每一帧的播放时长，总播放时长，总帧数。从而可以决定在某一时刻播放哪一帧画面。

```swift
public func applyEffect(at time: CMTime) -> CIImage? {
        let curTime = CMTimeSubtract(time, timeRange.start)
        var curTimeSeconds = CMTimeGetSeconds(curTime)
        if curTimeSeconds > totalDuration {
            // 这里需要重复播放
            curTimeSeconds -= totalDuration
        }
        var nearTime: TimeInterval = 0
        for i in 0..<frameCount {
            if nearTime >= curTimeSeconds {
                // get i
                if let imageSource = imageSource {
                    if let image = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                        return CIImage(cgImage: image)
                    }
                }
                break
            }
            nearTime += frameDuration
        }
        // 对于播放完了，那么直接取最后一帧显示，防止出现空白
        if frameCount > 0 {
            if let imageSource = imageSource {
                if let image = CGImageSourceCreateImageAtIndex(imageSource, frameCount - 1, nil) {
                    return CIImage(cgImage: image)
                }
            }
        }
        return nil
    }
```

![animate.gif](%E5%9F%BA%E4%BA%8E%E8%87%AA%E5%AE%9A%E4%B9%89AVVideoComposition%E7%9A%84%E8%A7%86%E9%A2%91%E8%B4%B4%E7%BA%B8%E5%92%8C%E7%89%B9%E6%95%88%E5%AE%9E%E7%8E%B0%20b9b65a0f19e84652b71be8d985025660/animate%201.gif)

除了静态贴纸和动态贴纸，我还提供了一种动画贴纸，并实现了四种基础动画类型：`opacity`透明度、`rotate`旋转、`scale`缩放、`translate`位移。除了透明度变化，其他的动画都是基于`CAAffineTransform`来实现的。原理就是计算当前的状态处于动画过程中的哪个阶段，从而计算出中间态。例如做旋转变化：

```swift
func handleAnimation(basic an: BasicAnimation, progress ratio: CGFloat, image: CIImage) -> CIImage {
guard an.from != nil && an.to != nil else {
            return image
        }
// 省略其他代码
    let by = an.anyFloatValue(an.from) + (an.anyFloatValue(an.to) - an.anyFloatValue(an.from)) * ratio
    return image.apply(rotate: by, extent: image.extent)

}
```

```swift
/// 旋转图片
    /// - Parameter rotate: 弧度
    /// - Parameter extent: 图片的真实尺寸：`CIImage.extent`
    /// - Returns: 返回旋转之后的图片
    func apply(rotate: CGFloat, extent: CGRect) -> CIImage {
        var t = CGAffineTransform.identity
        t = t.concatenating(CGAffineTransform(translationX: -(extent.origin.x + extent.width/2), y: -(extent.origin.y + extent.height/2)))
        t = t.concatenating(CGAffineTransform.init(rotationAngle: rotate))
        t = t.concatenating(CGAffineTransform(translationX: (extent.origin.x + extent.width/2), y: (extent.origin.y + extent.height/2)))
        return transformed(by: t)
    }
```

具体可以查看我有关[动画贴纸](https://github.com/ijinfeng/iVisual/blob/main/iVisual/Classes/AnimationOverlay.swift)的实现。

## 二、特效

TimeLine也对外提供了添加特效的接口，该接口要求提供一个遵循`SpecialEffectsProvider`协议的对象。

```swift
@discardableResult func insert(element: SpecialEffectsProvider) -> VisualElementIdentifer {
        let id = eidBuilder.get()
        element.visualElementId = id
        specialEffectsElementDic[id] = element
        renderCurrentFrameAgain()
        return id
    }
```

```swift
public protocol SpecialEffectsProvider: VisualProvider {
    func applyEffect(image: CIImage, at time: CMTime) -> CIImage?
}
```

这个协议非常简单，它会给你一个回调，这个回调函数有两个参数传递过来，`image`表示原始视图像，`time`表示播放到那一帧画面时的时间，并要求你返回处理后的图像。该协议也是继承于`VisualProvider`协议，这个协议在贴纸那一部分已经有所说明，这里不再细说。

其实看到这里，要给视频添加特效你应该也有想法了。我这里直接利用`CoreImage`框架，简单的给视频添加了几个特效，实现了视频扭曲效果、点状化效果。先看看扭曲效果。

![animate.gif](%E5%9F%BA%E4%BA%8E%E8%87%AA%E5%AE%9A%E4%B9%89AVVideoComposition%E7%9A%84%E8%A7%86%E9%A2%91%E8%B4%B4%E7%BA%B8%E5%92%8C%E7%89%B9%E6%95%88%E5%AE%9E%E7%8E%B0%20b9b65a0f19e84652b71be8d985025660/animate%202.gif)

可以看到视频在播放到1s至5s之间发生了扭曲。我利用了`CoreImage`中的滤镜`CIVortexDistortion`实现了这一效果。

代码如下：

```swift
/// 扭曲特效，基于`CIVortexDistortion`
public class DistortionEffects: SpecialEffectsProvider {
    public var visualElementId: VisualElementIdentifer = .invalid
    public var timeRange: CMTimeRange = .zero
    
    public var maxAngle: CGFloat = 360.0
    public var radius: CGFloat = 1800
    
    private let filter: CIFilter!
    
    public init() {
        filter = CIFilter(name: "CIVortexDistortion")
        
    }
    
    public func applyEffect(image: CIImage, at time: CMTime) -> CIImage? {
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: image.extent.center.x, y: image.extent.center.y), forKey: kCIInputCenterKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        let relateTime = CMTimeSubtract(time, timeRange.start)
        let ratio = CMTimeGetSeconds(relateTime) / CMTimeGetSeconds(timeRange.duration)
        filter.setValue(ratio * maxAngle, forKey: kCIInputAngleKey)
        return filter.outputImage
    }
}
```

同样的，使用起来也非常简单。只需要初始化一个特效对象，设置好生效时间范围，并插入到`TimeLine`中即刻。

```swift
let spe = DistortionEffects()
            spe.timeRange = CMTimeRange.init(start: CMTime.init(value: 1, timescale: 1), duration: CMTime.init(value: 4, timescale: 1))
            spe.maxAngle = 3600
timeLine.insert(element: spe)
        let videoCompostion = builder.buildVideoCompositon()
        playerItem.videoComposition = videoCompostion
        player.replaceCurrentItem(with: playerItem)
```

文章写到这里，其实关于视频添加贴纸和特效的原理和实现已经都讲完了。如果你要导出视频，那么直接将使用我们的`VideoComposition`生成器去生成一个即可，或直接使用AVPlayerItem中的那个合成器。导出后的视频就会自动添加上特效和贴纸。是不是非常方便。

```swift
let export = AVAssetExportSession.init(asset: playerItem.asset, presetName: AVAssetExportPresetHighestQuality)
            export?.outputURL = URL(fileURLWithPath: outputURL)
            export?.outputFileType = .mp4
            export?.shouldOptimizeForNetworkUse = true
            export?.videoComposition = builder.buildVideoCompositon()
            export?.exportAsynchronously {
// ...
}
```

具体的实现细节，大家可以下载我写的框架：[iVisual](https://github.com/ijinfeng/iVisual)

# 五、写在最后

在开发 iVisual 框架中遇到的问题记录：

1、CGAffinetransform

当我们在设置CIImage旋转或缩放时，默认的原点在image的左下角，因此我们需要先平移，将image的中心点位于原来的左下角位置，再做旋转或平移。

```swift
func apply(rotate: CGFloat, extent: CGRect) -> CIImage {
        var t = CGAffineTransform.identity
        t = t.concatenating(CGAffineTransform(translationX: -(extent.origin.x + extent.width/2), y: -(extent.origin.y + extent.height/2)))
        t = t.concatenating(CGAffineTransform.init(rotationAngle: rotate))
        t = t.concatenating(CGAffineTransform(translationX: (extent.origin.x + extent.width/2), y: (extent.origin.y + extent.height/2)))
        return transformed(by: t)
    }
    
    func apply(scale: CGFloat, extent: CGRect) -> CIImage {
        var t = CGAffineTransform.identity
        t = t.concatenating(CGAffineTransform(translationX: -(extent.origin.x + extent.width/2), y: -(extent.origin.y + extent.height/2)))
        t = t.concatenating(CGAffineTransform.init(scaleX: scale, y: scale))
        t = t.concatenating(CGAffineTransform(translationX: (extent.origin.x + extent.width/2), y: (extent.origin.y + extent.height/2)))
        return transformed(by: t)
    }
```

2、如何在播放中实时添加贴纸

当我们在播放时，`iVisual` 会实时根据 `TimeLine` 的上下文渲染出那一帧画面，而当我们暂停时， AVFoundation 已经提交了当前这一帧的画面，也就是 VideoComposition 中的 `asyncVideoCompositionRequest.finish(withComposedVideoFrame: pixelBuffer)` 。那么，如果在这一刻，一张新的贴纸被添加，那么在点击添加之后，需要立即显示出来。也就是这一帧画面要被重新合成并显示出来。但是 `AVFoundation` 并没有直接提供这么一个重绘的方法，因此，我们需要另寻他法。

1、在画面上覆盖一张假图

2、另`VideoComposition`重新渲染这一帧画面，尝试设置 `isFinished` 为false，但并没有效果

![截屏2021-11-15 下午3.55.08.png](%E5%9F%BA%E4%BA%8E%E8%87%AA%E5%AE%9A%E4%B9%89AVVideoComposition%E7%9A%84%E8%A7%86%E9%A2%91%E8%B4%B4%E7%BA%B8%E5%92%8C%E7%89%B9%E6%95%88%E5%AE%9E%E7%8E%B0%20b9b65a0f19e84652b71be8d985025660/%E6%88%AA%E5%B1%8F2021-11-15_%E4%B8%8B%E5%8D%883.55.08.png)

关于第二个问题，如果有同学有什么好的方法的话，欢迎讨论👏。
