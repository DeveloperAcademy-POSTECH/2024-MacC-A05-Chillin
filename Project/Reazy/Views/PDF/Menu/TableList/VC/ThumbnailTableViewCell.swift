//
//  ThumbnailTableViewCell.swift
//  Reazy
//
//  Created by 문인범 on 10/20/24.
//

import UIKit

class ThumbnailTableViewCell: UITableViewCell {

    let pageNum: Int
    
    let thumbnail: UIImage
    
    lazy var thumbnailView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.image = thumbnail
        return view
    }()
    
    lazy var pageNumLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(self.pageNum)"
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    init(pageNum: Int, thumbnail: UIImage) {
        self.pageNum = pageNum
        self.thumbnail = thumbnail
        
        super.init(style: .default, reuseIdentifier: nil)
        
        setUI()
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

extension ThumbnailTableViewCell {
    func setUI() {
        self.addSubview(pageNumLabel)
        NSLayoutConstraint.activate([
            pageNumLabel.widthAnchor.constraint(equalToConstant: 20),
            pageNumLabel.heightAnchor.constraint(equalToConstant: 10),
            pageNumLabel.centerXAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            pageNumLabel.centerYAnchor.constraint(equalTo: self.topAnchor, constant: 20)
        ])
        
        self.addSubview(thumbnailView)
        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: pageNumLabel.trailingAnchor),
            thumbnailView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            thumbnailView.topAnchor.constraint(equalTo: self.topAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
