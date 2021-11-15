//
//  FileBox.swift
//  FileBox
//
//  Created by jinfeng on 2021/9/24.
//

import UIKit

public class FileBox: NSObject {
    
    public static  let `default` = FileBox()
    
    internal var rootNode: FileNode?
    
    public func open(dir path: String = FileBox.sandBoxPath()) {
        let window = UIApplication.shared.windows.first!
        if let root = window.rootViewController {
            let rootNode = FileNode(path: path)
            FileBox.default.rootNode = rootNode
            let navi = createRootFileController(node: rootNode)
            root.present(navi, animated: true, completion: nil)
        }
    }
    
    public func openRecently(dir path: String = FileBox.sandBoxPath()) {
        guard let rootNode = rootNode else {
            open(dir: path)
            return
        }
        
        let navi = createRootFileController(node: FileNode(path: rootNode.path))
        var node: FileNode? = rootNode
        var vcs: [UIViewController] = []
        while node != nil {
            let vc = FileBoxTableViewController()
            vc.fileNode = FileNode(path: node!.path)
            vcs.append(vc)
            node = node?.next
        }
        navi.setViewControllers(vcs, animated: true)
        
        let window = UIApplication.shared.windows.first!
        if let root = window.rootViewController {
            root.present(navi, animated: true, completion: nil)
        }
    }
    
    private func createRootFileController(node: FileNode) -> UINavigationController {
        let vc = FileBoxTableViewController()
        vc.fileNode = node
        let navi = UINavigationController(rootViewController: vc)
        navi.modalPresentationStyle = .fullScreen
        return navi
    }
}

extension FileBox {
    public static func mainBundlePath() -> String {
        Bundle.main.bundlePath
    }
    
    public static func sandBoxPath() -> String {
        NSHomeDirectory()
    }
    
    public static func documentPath() -> String {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
    }
    
    public static func libraryPath() -> String {
        NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first ?? ""
    }
    
    public static func cachePath() -> String {
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
    }
    
    public static func tempPath() -> String {
        NSTemporaryDirectory()
    }
}


extension FileBox {
    func add(new node: FileNode) {
        var _node = FileBox.default.rootNode
        while _node?.next != nil {
            _node = _node?.next
        }
        _node?.next = node
    }
    
    func removeLastNode() {
        var _node = FileBox.default.rootNode
        while _node?.next?.next != nil {
            _node = _node?.next
        }
        if _node?.next != nil {
            _node?.next = nil
        }
    }
    
    func resetRootNode() {
        FileBox.default.rootNode?.next = nil
    }
}


