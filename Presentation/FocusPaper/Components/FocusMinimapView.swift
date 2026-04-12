//
//  FocusMinimapView.swift
//  Reazy
//
//  Created by 문인범 on 1/28/26.
//

import UIKit
import PDFKit



class FocusMinimapView: UIView {
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .white
        view.layer.cornerRadius = 2
        view.layer.borderColor = UIColor.gray400.cgColor
        view.layer.borderWidth = 1.0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "5f5daa").withAlphaComponent(0.2)
        view.layer.borderColor = UIColor.primary1.cgColor
        view.layer.borderWidth = 1.0
        return view
    }()
    
    private var currentPage: PDFPage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpUI() {
        self.backgroundColor = .white
        self.clipsToBounds = false
        imageView.clipsToBounds = false
        
        addSubview(imageView)
        addSubview(indicatorView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    func update(page: PDFPage, visibleRect: CGRect) {
        // 썸네일 생성
        if currentPage != page {
            currentPage = page
            let thumbnailSize = self.bounds.size
            
            // UI 끊김 방지를 위해 백그라운드 스레드에서 썸네일 생성
            DispatchQueue.global(qos: .userInteractive).async {
                let thumbnail = page.thumbnail(of: thumbnailSize, for: .mediaBox)
                DispatchQueue.main.async {
                    // 생성하는 동안 페이지가 바뀌지 않았는지 확인
                    if self.currentPage == page {
                        self.imageView.image = thumbnail
                    }
                }
            }
        }
        
        let viewWidth = self.bounds.width
        let viewHeight = self.bounds.height
        
        let indicatorX = visibleRect.origin.x * viewWidth
        let indicatorY = visibleRect.origin.y * viewHeight // UIKit 기준 (상단이 0)
        let indicatorW = visibleRect.width * viewWidth
        let indicatorH = visibleRect.height * viewHeight
        
        UIView.animate(withDuration: 0.1) {
            self.indicatorView.frame = CGRect(x: indicatorX, y: indicatorY, width: indicatorW, height: indicatorH)
        }
    }
}
