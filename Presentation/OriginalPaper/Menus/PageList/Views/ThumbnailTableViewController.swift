//
//  ThumbnailTableViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/20/24.
//

import SwiftUI
import UIKit
import Combine


/**
 썸네일 ViewController(페이지 리스트)
 */
final class ThumbnailTableViewController: UIViewController {
    let pageListViewModel: PageListViewModel
    
    var cancellables: Set<AnyCancellable> = []
    
    init(pageListViewModel: PageListViewModel) {
        self.pageListViewModel = pageListViewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    
    lazy var thumbnailTableView: UITableView = {
        let view = UITableView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        return view
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUI()
        setBinding()

//        self.pageListViewModel.getPageThumbnails {
//            self.thumbnailTableView.reloadData()
//        }
    }
    
    deinit {
        self.cancellables.forEach { $0.cancel() }
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
    
    private func setBinding() {
        
        self.pageListViewModel.$changedPageNumber
            .sink { [weak self] num in
                guard let num = num else { return }
                NotificationCenter.default.post(name: .didSelectThumbnail, object: self, userInfo: ["num": num])
                self?.thumbnailTableView.scrollToRow(at: .init(row: num, section: 0), at: .top, animated: true)
            }
            .store(in: &self.cancellables)
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.redrawScreen()
            }
            .store(in: &self.cancellables)
    }
    

    private func redrawScreen() {
        self.thumbnailTableView.reloadData()
    }
}


// MARK: - UITableView Delegate
extension ThumbnailTableViewController: UITableViewDelegate, UITableViewDataSource {
    /// 페이지 리스트 갯수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.pageListViewModel.thumnailImages.count
    }
    
    /// 들어갈 셀 추가
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        
        let cell = ThumbnailTableViewCell(pageNum: row, thumbnail: self.pageListViewModel.thumnailImages[row])
        if self.pageListViewModel.changedPageNumber == row {
            cell.selectCell()
        } else if self.pageListViewModel.changedPageNumber == nil, row == 0 {
            cell.selectCell()
        }
        
        return cell
    }
    
    /// 셀 높이
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UIScreen.main.bounds.width * 0.2
    }
    
    /// 셀 선택 되었을 때
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let cell = tableView.cellForRow(at: indexPath) as? ThumbnailTableViewCell else { return }
        
        NotificationCenter.default.post(name: .didSelectThumbnail, object: self, userInfo: ["num": indexPath.row])
        self.pageListViewModel.changedPageNumber = indexPath.row
        self.pageListViewModel.goToPage(at: indexPath.row)
    }
}
