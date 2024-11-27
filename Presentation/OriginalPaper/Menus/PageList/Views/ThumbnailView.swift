//
//  ThumbnailView.swift
//  Reazy
//
//  Created by 문인범 on 10/20/24.
//

import SwiftUI

/**
 썸네일 뷰 컨트롤러 -> SwiftUI
 */
struct ThumbnailView: UIViewControllerRepresentable {
    @EnvironmentObject private var pageListViewModel: PageListViewModel
    
    typealias UIViewControllerType = ThumbnailTableViewController
    
    func makeUIViewController(context: Context) -> ThumbnailTableViewController {
        .init(pageListViewModel: self.pageListViewModel)
    }
    
    func updateUIViewController(_ uiViewController: ThumbnailTableViewController, context: Context) { }
}
