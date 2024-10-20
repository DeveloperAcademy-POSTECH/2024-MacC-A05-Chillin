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
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 4
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.primary3.cgColor
        return view
    }()
    
    lazy var pageNumLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(self.pageNum + 1)"
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
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
}

extension ThumbnailTableViewCell {
    func setUI() {
        self.addSubview(pageNumLabel)
        self.addSubview(thumbnailView)
        
        let ratio = thumbnail.size.width / thumbnail.size.height
        
        NSLayoutConstraint.activate([
            thumbnailView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            thumbnailView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            thumbnailView.heightAnchor.constraint(equalToConstant: 210 ),
            thumbnailView.widthAnchor.constraint(equalToConstant: 210 * ratio)
        ])
        
        NSLayoutConstraint.activate([
            pageNumLabel.trailingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            pageNumLabel.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            pageNumLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        ])
    }
}
