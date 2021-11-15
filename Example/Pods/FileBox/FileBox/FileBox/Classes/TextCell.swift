//
//  TextCell.swift
//  TextCell
//
//  Created by jinfeng on 2021/9/24.
//

import UIKit
import SnapKit

class TextCell: UITableViewCell {
    
    private let label: UILabel = {
       let l = UILabel()
        l.textColor = .black
        l.font = .systemFont(ofSize: 16)
        return l
    }()
    
    var fileNode: FileNode? {
        didSet {
            label.text = fileNode?.name
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.centerY.equalTo(contentView)
            make.right.lessThanOrEqualTo(-12)
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
