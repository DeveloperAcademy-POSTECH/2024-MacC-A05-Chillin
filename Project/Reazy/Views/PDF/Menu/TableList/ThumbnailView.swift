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
    @EnvironmentObject var viewModel: OriginalViewModel
    
    typealias UIViewControllerType = ThumbnailTableViewController
    
    func makeUIViewController(context: Context) -> ThumbnailTableViewController {
        .init(viewModel: self.viewModel)
    }
    
    func updateUIViewController(_ uiViewController: ThumbnailTableViewController, context: Context) { }
}
