//
//  OriginalViewRepresentable.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import SwiftUI

/// PDFView를 SwiftUI로 사용 위한 변환 구조체
struct OriginalViewControllerRepresent: UIViewControllerRepresentable {
    typealias UIViewControllerType = OriginalViewController
    
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject private var focusFigureViewModel: FocusFigureViewModel
    @EnvironmentObject private var pageListViewModel: PageListViewModel
    @EnvironmentObject private var searchViewModel: SearchViewModel
    @EnvironmentObject private var indexViewModel: IndexViewModel
    @EnvironmentObject var commentViewModel: CommentViewModel
    @EnvironmentObject var backpageBtnViewModel: BackPageBtnViewModel
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        OriginalViewController(
            viewModel: mainPDFViewModel,
            commentViewModel: commentViewModel,
            originalViewModel: focusFigureViewModel,
            pageListViewModel: pageListViewModel,
            searchViewModel: searchViewModel,
            indexViewModel: indexViewModel,
            backpageBtnViewModel: backpageBtnViewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    
    }
}
