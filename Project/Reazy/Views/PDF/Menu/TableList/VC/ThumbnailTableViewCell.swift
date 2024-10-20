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
        view.clipsToBounds = true
        return view
    }()
    
    lazy var pageNumLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "\(self.pageNum + 1)"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .init(hex: "9092A9")
        label.textAlignment = .center
        return label
    }()
    
    init(pageNum: Int, thumbnail: UIImage) {
        self.pageNum = pageNum
        self.thumbnail = thumbnail
        super.init(style: .default, reuseIdentifier: nil)
        
        setUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(isMyCell), name: .didSelectThumbnail, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
    
    @objc
    private func isMyCell(_ notification: Notification) {
        guard let obj = notification.userInfo?["num"] as? Int else { return }
        if obj == self.pageNum {
            thumbnailView.layer.borderWidth = 2
            thumbnailView.layer.borderColor = UIColor.primary1.cgColor
            pageNumLabel.textColor = .primary1
        } else {
            thumbnailView.layer.borderWidth = 1
            thumbnailView.layer.borderColor = UIColor.primary3.cgColor
            pageNumLabel.textColor = .init(hex: "9092A9")
        }
    }
}
