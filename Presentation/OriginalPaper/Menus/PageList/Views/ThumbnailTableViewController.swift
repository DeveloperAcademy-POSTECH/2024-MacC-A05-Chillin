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
    
    var preRenderedCells: [ThumbnailTableViewCell] = []
    
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
        cacheCells()
        setUI()
        setBinding()
    }
    
    deinit {
        self.cancellables.forEach { $0.cancel() }
    }
}

// MARK: - UI 초기 설정
extension ThumbnailTableViewController {
    private func cacheCells() {
        self.preRenderedCells = pageListViewModel.thumnailImages.enumerated().map { index, thumbnail in
            ThumbnailTableViewCell(pageNum: index, thumbnail: thumbnail)
        }
    }
    
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
                guard let self = self, let num = num else { return }
                
                NotificationCenter.default.post(name: .didSelectThumbnail, object: self, userInfo: ["num": num])
                DispatchQueue.main.async {
                    self.thumbnailTableView.reloadData() /// 데이터 리로드
                    DispatchQueue.main.async {
                        let totalRows = self.thumbnailTableView.numberOfRows(inSection: 0)
                        let targetRow = num
                        if targetRow < totalRows && targetRow >= 0 {
                            self.thumbnailTableView.scrollToRow(
                                at: IndexPath(row: targetRow, section: 0),
                                at: .top,
                                animated: true
                            )
                        } else {
                            print("Invalid row: \(targetRow). Total rows: \(totalRows)")
                        }
                    }
                }
            }
            .store(in: &self.cancellables)
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.preRenderedCells.forEach { $0.updateOrientationConstraints() }
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
            return preRenderedCells[indexPath.row]
        }
    
    /// 셀 높이
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UIScreen.main.bounds.width * 0.2
    }
    
    /// 셀 선택 되었을 때
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: .didSelectThumbnail, object: self, userInfo: ["num": indexPath.row])
        self.pageListViewModel.changedPageNumber = indexPath.row
        self.pageListViewModel.goToPage(at: indexPath.row)
    }
}
