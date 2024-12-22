//
//  ThumbnailTableViewCell.swift
//  Reazy
//
//  Created by 문인범 on 10/20/24.
//

import UIKit
import Combine

/**
 페이지 리스트 TableView
 */
class ThumbnailTableViewCell: UITableViewCell {
    private var cancellables: Set<AnyCancellable> = []

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
    
    // thumbnailView 제약조건
    private var thumbnailConstraints: [NSLayoutConstraint] = []
    
    // pageNumLabelView 제약조건
    private var pageNumConstraints: [NSLayoutConstraint] = []
    
    init(pageNum: Int, thumbnail: UIImage) {
        self.pageNum = pageNum
        self.thumbnail = thumbnail
        super.init(style: .default, reuseIdentifier: nil)
        
        setUI()
        
        NotificationCenter.default.publisher(for: .didSelectThumbnail)
            .sink { [weak self] in
                self?.isMyCell($0)
            }
            .store(in: &self.cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    deinit {
        self.cancellables.forEach { $0.cancel() }
    }
}

extension ThumbnailTableViewCell {
    /// UI 초기 설정
    func setUI() {
        self.selectionStyle = .none
        
        self.addSubview(pageNumLabel)
        self.addSubview(thumbnailView)
        
        let viewWidth = UIScreen.main.bounds.width * 0.22 * 0.65
        
        let ratio = thumbnail.size.width / thumbnail.size.height
        
        if ratio > 1 {
            let heightRatio = thumbnail.size.height / thumbnail.size.width
            
            self.thumbnailConstraints.append(contentsOf: [
                thumbnailView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                thumbnailView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                thumbnailView.heightAnchor.constraint(equalToConstant: viewWidth * heightRatio ),
                thumbnailView.widthAnchor.constraint(equalToConstant: viewWidth )
            ])
        } else {
            self.thumbnailConstraints.append(contentsOf: [
                thumbnailView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                thumbnailView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                thumbnailView.heightAnchor.constraint(equalToConstant: viewWidth ),
                thumbnailView.widthAnchor.constraint(equalToConstant: viewWidth * ratio )
            ])
        }
        
        self.pageNumConstraints.append(contentsOf: [
            pageNumLabel.trailingAnchor.constraint(equalTo: thumbnailView.leadingAnchor),
            pageNumLabel.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            pageNumLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
        ])
        
        NSLayoutConstraint.activate(thumbnailConstraints)
        NSLayoutConstraint.activate(pageNumConstraints)
    }
    
    /// Notification에 따른 Cell UI 수정
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
    
    // 화면이 회전되었을 때 레이아웃 수정
    public func updateOrientationConstraints() {
        let heightAnchor = self.thumbnailConstraints.first { $0.firstAttribute == .height }
        let widthAnchor = self.thumbnailConstraints.first { $0.firstAttribute == .width }
        
        let viewWidth = UIScreen.main.bounds.width * 0.22 * 0.65

        let ratio = thumbnail.size.width / thumbnail.size.height

        if ratio > 1 {
            let newRatio = thumbnail.size.height / thumbnail.size.width
            heightAnchor?.constant = viewWidth * newRatio
            widthAnchor?.constant = viewWidth
        } else {
            heightAnchor?.constant = viewWidth
            widthAnchor?.constant = viewWidth * ratio
        }
    }
}
