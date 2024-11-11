//
//  ThumbnailTableViewCell.swift
//  Reazy
//
//  Created by 문인범 on 10/20/24.
//

import UIKit


/**
 페이지 리스트 TableView
 */
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
        label.font = .reazyManualFont(.semibold, size: 14)
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
    /// UI 초기 설정
    func setUI() {
        self.selectionStyle = .none
        
        self.addSubview(pageNumLabel)
        self.addSubview(thumbnailView)
        
        let viewWidth = UIScreen.main.bounds.width * 0.22 * 0.7
        
        let ratio = thumbnail.size.width / thumbnail.size.height
        
        NSLayoutConstraint.activate([
            thumbnailView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            thumbnailView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            thumbnailView.heightAnchor.constraint(equalToConstant: viewWidth ),
            thumbnailView.widthAnchor.constraint(equalToConstant: viewWidth * ratio)
        ])
        
        NSLayoutConstraint.activate([
            pageNumLabel.trailingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            pageNumLabel.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            pageNumLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        ])
    }
    
    /// Notification에 따른 Cell UI 수정
    @objc
    private func isMyCell(_ notification: Notification) {
        guard let obj = notification.userInfo?["num"] as? Int else { return }
        if obj == self.pageNum {
            selectCell()
        } else {
            deselectCell()
        }
    }
    
    /// Cell 선택된 이미지로 수정
    public func selectCell() {
        thumbnailView.layer.borderWidth = 2
        thumbnailView.layer.borderColor = UIColor.primary1.cgColor
        pageNumLabel.textColor = .primary1
        pageNumLabel.font = .reazyManualFont(.semibold, size: 14)
    }
    
    /// Cell 미선택된 이미지로 수정
    private func deselectCell() {
        thumbnailView.layer.borderWidth = 1
        thumbnailView.layer.borderColor = UIColor.primary3.cgColor
        pageNumLabel.textColor = .init(hex: "9092A9")
        pageNumLabel.font = .reazyManualFont(.medium, size: 14)
    }
}
