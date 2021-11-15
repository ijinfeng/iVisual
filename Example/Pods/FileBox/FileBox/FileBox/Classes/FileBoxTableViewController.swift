//
//  FileBoxTableViewController.swift
//  FileBoxTableViewController
//
//  Created by jinfeng on 2021/9/24.
//

import UIKit
import AVKit
import QuickLook

class FileBoxTableViewController: UITableViewController {
    
    var fileNode: FileNode?
    
    var fileNodes: [FileNode] = []
    
    private var rootFileNode: FileNode!
    private var topFileNode: FileNode!
    
    private var clickFileNode: FileNode?
    
    private var numLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if fileNode == nil {
            fileNode = FileNode(path: FileBox.sandBoxPath())
        }

        if let node = fileNode {
            rootFileNode = FileNode(actionNode: node.path, action: .root)
            topFileNode = FileNode(actionNode: node.path.topFilePath(), action: .top)
        }
        
        self.fileNodes = fileNode?.refreshNodes() ?? []
        navigationItem.title = fileNode?.name ?? ""
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: UIImage.create(named: "icon_close")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(onClickBack))
        let refreshItem = UIBarButtonItem.init(image: UIImage.create(named: "icon_refresh")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(onClickRefresh))
        let deleteItem = UIBarButtonItem.init(image: UIImage.create(named: "icon_delete")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(onClickDelete))
        navigationItem.rightBarButtonItems = [refreshItem, deleteItem]
        
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        tableView.register(TextCell.self, forCellReuseIdentifier: "text")
        tableView.register(DisplayFileCell.self, forCellReuseIdentifier: "display")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 {
            return 2
        }
        return self.fileNodes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "text", for: indexPath) as! TextCell
            if indexPath.row == 0 {
                cell.fileNode = rootFileNode
            } else {
                cell.fileNode = topFileNode
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "display", for: indexPath) as! DisplayFileCell
            let fileNode = self.fileNodes[indexPath.row]
            cell.fileNode = fileNode
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                navigationController?.popToRootViewController(animated: true)
                FileBox.default.resetRootNode()
            } else {
                navigationController?.popViewController(animated: true)
                FileBox.default.removeLastNode()
            }
        } else {
            let fileNode = self.fileNodes[indexPath.row]
            clickFileNode = fileNode
            if fileNode.isDir {
                
                FileBox.default.add(new: fileNode)
                
                let vc = FileBoxTableViewController()
                vc.fileNode = fileNode
                navigationController?.pushViewController(vc, animated: true)
            } else {
                tableView.deselectRow(at: indexPath, animated: true)
                
                switch fileNode.type {
                case .audio, .video:
                    let vc = AVPlayerViewController()
                    vc.player = AVPlayer.init(url: URL(fileURLWithPath: fileNode.path))
                    navigationController?.pushViewController(vc, animated: true)
                    return
                default:
                    let vc = QLPreviewController()
                    vc.dataSource = self
                    navigationController?.pushViewController(vc, animated: true)
                    return
                }
                
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 40
        } else {
            return 60
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 20
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            var header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header")
            if header == nil {
                header = UITableViewHeaderFooterView.init(reuseIdentifier: "header")
                header?.contentView.backgroundColor = .clear
                
                let numLabel = UILabel()
                self.numLabel = numLabel
                numLabel.font = UIFont.systemFont(ofSize: 10)
                numLabel.textColor = .black
                header?.contentView.addSubview(numLabel)
                numLabel.snp.makeConstraints { make in
                    make.center.equalTo(header!.contentView)
                }
            }
            var fileCount = 0
            var dirCount = 0
            for fileNode in fileNodes {
                if fileNode.isDir {
                    dirCount += 1
                } else {
                    fileCount += 1
                }
            }
            numLabel?.text = "files \(fileCount) | directorys \(dirCount)"
            return header
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        let fileNode = fileNodes[indexPath.row]
        if fileNode.isDeletable() {
           return "删除"
        }
        return "无权限删除"
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let fileNode = fileNodes[indexPath.row]
        guard fileNode.isDeletable() else {
            return
        }
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: fileNode.path))
            fileNodes.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .none)
        } catch {}
    }
}

extension FileBoxTableViewController {
    @objc func onClickBack() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func onClickRefresh() {
        guard let node = fileNode else {
            return
        }
        self.fileNodes = node.refreshNodes()
        self.tableView.reloadData()
    }
    
    @objc func onClickDelete() {
        if fileNodes.count == 0 {
            return
        }
        
        let alert = UIAlertController(title: "清空操作", message: "即将删除当前目录下的所有文件和文件夹", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "取消", style: .cancel) {_ in }
        let sure = UIAlertAction(title: "删除", style: .destructive) { _ in
            let fileManager = FileManager.default
            for fileNode in self.fileNodes {
               try? fileManager.removeItem(at: URL(fileURLWithPath: fileNode.path))
            }
            self.fileNodes = self.fileNode?.refreshNodes() ?? []
            self.tableView.reloadData()
        }
        alert.addAction(cancel)
        alert.addAction(sure)
        present(alert, animated: true, completion: nil)
    }
}


extension FileBoxTableViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        NSURL(fileURLWithPath: clickFileNode!.path)
    }
}
