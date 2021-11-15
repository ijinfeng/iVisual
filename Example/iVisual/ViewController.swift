//
//  ViewController.swift
//  iVisual
//
//  Created by ijinfeng on 11/15/2021.
//  Copyright (c) 2021 ijinfeng. All rights reserved.
//

import UIKit
import iVisual
import CoreMedia
import FileBox

class ViewController: UITableViewController {

    let datas: [String] =
    ["静态贴纸",
    "动态贴纸",
    "动画贴纸",
    "特效",
    "播放过程中添加",]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "沙盒", style: .plain, target: self, action: #selector(onClickOpenSandBox))
        
    }
    
    @objc func onClickOpenSandBox() {
        FileBox.default.openRecently()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        datas.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = datas[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = VideoPlayerViewController()
        navigationController?.pushViewController(vc, animated: true)
        
        switch indexPath.row {
        case 0:
            // 静态贴纸
            let uiimage = UIImage(named: "biaozhun")!
            let ciimage = CIImage(cgImage: uiimage.cgImage!)
            let image = StaticImageOverlay.init(image: ciimage)
            image.timeRange = CMTimeRange.init(start: CMTime.init(value: 0, timescale: 1), end: CMTime.init(value: 2, timescale: 1))
            image.frame = CGRect(x: 20, y: 20, width: 160, height: 60)
            vc.addOverlay(image)
        case 1:
            let filePath = Bundle.main.path(forResource: "shafa", ofType: "gif") ?? ""
            let gif = DynamicImageOverlay(filePath: filePath)
            gif.timeRange = CMTimeRange.init(start: CMTime.init(value: 1, timescale: 1), duration: CMTime.init(value: 8, timescale: 1))
            gif.frame = CGRect(x: 20, y: 100, width: 100, height: 80)
            vc.addOverlay(gif)
        case 2:
            let uiimage = UIImage(named: "biaozhun")!
            let ciimage = CIImage(cgImage: uiimage.cgImage!)
            
            let overlay = AnimationOverlay(image: ciimage)
            overlay.timeRange = CMTimeRange.init(start: CMTime.init(value: 0, timescale: 1), duration: CMTime.init(value: 6, timescale: 1))
            overlay.frame = CGRect(x: 20, y: 0, width: 80, height: 80)
            
            let an = BasicAnimation()
            an.duration = CMTime.init(value: 3, timescale: 2)
            an.isAutoreverse = true
            an.isRepeat = false
            an.type = .opacity
            an.from = 0.5
            an.to = 1
            overlay.add(animation: an, for: "basic")
            
            let key = KeyFrameAnimation()
            key.type = .translate
            key.values = [CGPoint(x: 50, y: 50),CGPoint(x: 0, y: 0),CGPoint(x: 50, y: 100),CGPoint(x: -20, y: 30) ]
            overlay.add(animation: key, for: "key")
            vc.addOverlay(overlay)
        case 4:
            vc.addInPlaying = true
        case 3:
            let spe = DistortionEffects()
            spe.timeRange = CMTimeRange.init(start: CMTime.init(value: 1, timescale: 1), duration: CMTime.init(value: 4, timescale: 1))
            spe.maxAngle = 3600
            vc.addEffects(spe)
        default:
            return
        }
    }
}

