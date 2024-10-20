//
//  ThumbnailTableViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/20/24.
//

import SwiftUI
import UIKit


/**
 썸네일 뷰 컨트롤러(페이지 리스트)
 */
final class ThumbnailTableViewController: UIViewController {
    
    let viewModel: OriginalViewModel
    
    init(viewModel: OriginalViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    
    lazy var thumbnailTableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.dataSource = self
        view.register(ThumbnailTableViewCell.self, forCellReuseIdentifier: "thumbnail")
        return view
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
    }
}

// MARK: - UI 초기 설정
extension ThumbnailTableViewController {
    private func setUI() {
        self.view.addSubview(self.thumbnailTableView)
        NSLayoutConstraint.activate([
            self.thumbnailTableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.thumbnailTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.thumbnailTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.thumbnailTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
    }
}

// MARK: - UITableView Delegate
extension ThumbnailTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.viewModel.thumnailImages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ThumbnailTableViewCell(pageNum: indexPath.row, thumbnail: self.viewModel.thumnailImages[indexPath.row])
        return cell
    }
}
