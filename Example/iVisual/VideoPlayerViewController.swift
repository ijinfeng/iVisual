//
//  VideoPlayerViewController.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/10/14.
//

import UIKit
import AVFoundation
import MediaPlayer
import iVisual
import SnapKit

class VideoPlayerViewController: UIViewController {

    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var slider: UISlider = UISlider()
    
    var isPlaying: Bool = false
    
    var timeLabel: UILabel = UILabel()
    
    var expoertButton: UIButton = UIButton()
    
    var playerItem: AVPlayerItem!
    
    
    var timeLine: TimeLine!
    var builder: VideoCompositionBuilder!
    
    var addInPlaying = false {
        didSet {
            if addInPlaying {
                let add = UIButton()
                add.setTitle("添加贴纸", for: .normal)
                add.setTitleColor(.white, for: .normal)
                add.addTarget(self, action: #selector(onClickAddOverlay), for: .touchUpInside)
                add.sizeToFit()
                navigationItem.titleView = add
                
                let videoCompostion = builder.buildVideoCompositon()
                playerItem.videoComposition = videoCompostion
            }
        }
    }
    

    
    deinit {
        print("=============deinit==========")
        player.removeObserver(self, forKeyPath: "status")
        player.currentItem?.removeObserver(self, forKeyPath: "duration")
        player.pause()
    }
    
    init() {
        let path = Bundle.main.path(forResource: "sample_clip1", ofType: "m4v")
        let URL = URL(fileURLWithPath: path ?? "")
        let asset = AVURLAsset(url: URL)
        let item = AVPlayerItem.init(asset: asset)
        self.playerItem = item
        
        timeLine = TimeLine(asset: asset)
        timeLine.contentMode = .scaleAspectFill
        timeLine.renderSize = CGSize(width: 1800, height: 1800)
        timeLine.backgroundColor = UIColor.clear
        builder = VideoCompositionBuilder.init(exist: nil, timeLine: timeLine)
        
        player = AVPlayer.init(playerItem: playerItem)
        playerLayer = AVPlayerLayer.init(player: player)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .lightGray
        
        changeNavigationItem()
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        playerLayer.backgroundColor = UIColor.clear.cgColor
        playerLayer.frame = view.bounds
        view.layer.insertSublayer(playerLayer, at: 0)
        
        slider.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - 88, width: view.bounds.size.width, height: 30)
        view.addSubview(slider)
        
        slider.addTarget(self, action: #selector(onSliderDidChange), for: .valueChanged)
        
        timeLabel.text = "00:00"
        timeLabel.textColor = .white
        view.addSubview(timeLabel)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textAlignment = .center
        timeLabel.frame = CGRect(x: 0, y: slider.frame.minY + 25, width: view.frame.size.width, height: 25)
        
        player.addPeriodicTimeObserver(forInterval: CMTime.init(value: CMTimeValue(1), timescale: 10), queue: DispatchQueue.main) { [weak self] t in
//            print("tttt= \(CMTimeShow(t))")
            
            self?.slider.value = Float(CMTimeGetSeconds(t))
            
            let seconds = CMTimeGetSeconds(t)
            
            self?.timeLabel.text = "00:"+String(format: "%02.0f", seconds)
        }
        
        player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        playerItem.addObserver(self, forKeyPath: "duration", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        expoertButton.setTitle("导出视频", for: .normal)
        expoertButton.sizeToFit()
        expoertButton.setTitleColor(.white, for: .normal)
        expoertButton.addTarget(self, action: #selector(onLickExpoert), for: .touchUpInside)
        view.addSubview(expoertButton)
        expoertButton.snp.makeConstraints { make in
            make.centerX.equalTo(view)
            make.top.equalTo(100)
        }
    }
    
    override  func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let path = keyPath {
            if path == "status" && player.status == .readyToPlay {

                let duration = player.currentItem?.duration
                print(duration ?? .zero)
                navigationItem.rightBarButtonItem?.isEnabled = true
                print("准备好了--------")
            }
            if path == "duration" {
                if let duration = player.currentItem?.duration, duration > CMTime.zero {
                    slider.maximumValue = Float(CMTimeGetSeconds(duration))
                }
            }
        }
    }
    
    @objc func didPlayEnd() {
        print("播放结束")
        
        self.player.seek(to: .zero)
        self.player.play()
    }
    
    @objc func onClickAddOverlay() {
        let uiimage = UIImage(named: "biaozhun")!
        let ciimage = CIImage(cgImage: uiimage.cgImage!)
        let image = StaticImageOverlay.init(image: ciimage)
        print("在当前时间: \(CMTimeShow(timeLine.currentTime)) 添加贴纸")
        image.timeRange = CMTimeRange.init(start: CMTimeSubtract(timeLine.currentTime, CMTime.init(value: 1, timescale: 1)), duration: CMTime.init(value: 2, timescale: 1))
        image.frame = CGRect(x: 20, y: 60, width: 160, height: 160)
        timeLine.insert(element: image)
        
        
//        let videoCompostion = builder.buildVideoCompositon()
//        playerItem.videoComposition = videoCompostion
        
//        let cur = playerItem.currentTime()
        player.replaceCurrentItem(with: playerItem)
    }
    
    
    @objc func onClickPlayer() {
        isPlaying = !isPlaying
        if isPlaying {
            player.play()
        } else {
            player.pause()
        }
        changeNavigationItem()
    }
    
    func changeNavigationItem() {
        if isPlaying {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .stop, target: self, action: #selector(onClickPlayer))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .play, target: self, action: #selector(onClickPlayer))
        }
    }
    
    func addOverlay(_ o: OverlayProvider) {
        timeLine.insert(element: o)
        let videoCompostion = builder.buildVideoCompositon()
        playerItem.videoComposition = videoCompostion
        player.replaceCurrentItem(with: playerItem)
    }
    
    func addEffects(_ e: SpecialEffectsProvider) {
        timeLine.insert(element: e)
        let videoCompostion = builder.buildVideoCompositon()
        playerItem.videoComposition = videoCompostion
        player.replaceCurrentItem(with: playerItem)
    }

    @objc func onSliderDidChange() {
        player.pause()
        isPlaying = false
        changeNavigationItem()
        
        let t = CMTime.init(seconds: Double(slider.value), preferredTimescale: player.currentItem!.duration.timescale)
        player.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    // MARK: 导出视频
    @objc func onLickExpoert() {
        let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/record/"
        let fileManager = FileManager.default
         if !fileManager.fileExists(atPath: path) {
             do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
             } catch {
                 print(error)
             }
         }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HH:mm:ss"
        let videoName = f.string(from: Date())
        let outputURL = path + "\(videoName).mp4"
        do {
            print("开始导出....")
            let export = AVAssetExportSession.init(asset: playerItem.asset, presetName: AVAssetExportPresetHighestQuality)
            export?.outputURL = URL(fileURLWithPath: outputURL)
            export?.outputFileType = .mp4
            export?.shouldOptimizeForNetworkUse = true
            export?.videoComposition = builder.buildVideoCompositon()
            export?.exportAsynchronously {
                DispatchQueue.main.async {
                    switch export!.status {
                    case .completed:
                        print("导出成功")
                    default:
#if DEBUG
                        if export!.error != nil {
                            print("====> export error detail:\n\t \(export!.error!)")
                        }
#endif
                    }
                }
            }
        }
    }
}

