//
//  DisplayFileCell.swift
//  DisplayFileCell
//
//  Created by jinfeng on 2021/9/24.
//

import UIKit
import SnapKit

class DisplayFileCell: UITableViewCell {

    private let icon: UIImageView = {
       let img = UIImageView()
        img.backgroundColor = .clear
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    private let fileAbleLabel: UILabel = {
        let l = UILabel()
         l.textColor = .lightGray
         l.font = .systemFont(ofSize: 11)
         return l
    }()
    
    private let label: UILabel = {
       let l = UILabel()
        l.textColor = .black
        l.font = .systemFont(ofSize: 16)
        return l
    }()
    
    private let subLabel: UILabel = {
        let l = UILabel()
         l.textColor = .lightGray
         l.font = .systemFont(ofSize: 14)
         return l
    }()
    
    private let createLabel: UILabel = {
        let l = UILabel()
         l.textColor = .lightGray
         l.font = .systemFont(ofSize: 14)
         return l
    }()
    
    private let rightArrow: UIImageView = {
        let img = UIImageView()
        img.image = UIImage.create(named: "icon_right_arrow")
         img.backgroundColor = .clear
         img.contentMode = .scaleAspectFit
         return img
    }()
    
    var fileNode: FileNode? {
        didSet {
            guard let fileNode = fileNode else {
                return
            }
            label.text = fileNode.name
            icon.image = fileNode.getShowIcon()
            subLabel.text = fileNode.fileSize()
            rightArrow.isHidden = !fileNode.isDir
            fileAbleLabel.isHidden = fileNode.isDir
            var ableText = ""
            ableText.append(fileNode.isReadable() ? "r" : "*")
            ableText.append("/")
            ableText.append(fileNode.isWritable() ? "w" : "*")
            ableText.append("/")
            ableText.append(fileNode.isExecutable() ? "x" : "*")
            ableText.append("/")
            ableText.append(fileNode.isDeletable() ? "d" : "*")
            fileAbleLabel.text = ableText
            createLabel.isHidden = fileNode.isDir
            if let date = fileNode.createDate() {
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "yyyy.MM.dd HH:mm:ss"
                createLabel.text = dateFormat.string(from: date)
            } else {
                createLabel.text = ""
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(icon)
        contentView.addSubview(label)
        contentView.addSubview(subLabel)
        contentView.addSubview(rightArrow)
        contentView.addSubview(fileAbleLabel)
        contentView.addSubview(createLabel)
        
        label.snp.makeConstraints { make in
            make.left.equalTo(icon.snp_right).offset(15)
            make.centerY.equalTo(icon)
            make.right.lessThanOrEqualTo(-50)
        }
        
        icon.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.top.equalTo(4)
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
        fileAbleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(icon)
            make.top.equalTo(icon.snp_bottom).offset(3)
        }
        
        subLabel.snp.makeConstraints { make in
            make.left.equalTo(label)
            make.right.lessThanOrEqualTo(contentView).offset(-50)
            make.top.equalTo(label.snp_bottom).offset(5)
        }
        rightArrow.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.right.equalTo(-12)
        }
        createLabel.snp.makeConstraints { make in
            make.right.equalTo(-50)
            make.centerY.equalTo(subLabel)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
