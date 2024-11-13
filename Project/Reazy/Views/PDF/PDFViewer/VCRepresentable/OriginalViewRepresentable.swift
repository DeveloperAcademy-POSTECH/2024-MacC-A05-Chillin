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
    @StateObject var commentViewModel: CommentViewModel
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        OriginalViewController(viewModel: mainPDFViewModel, commentViewModel: commentViewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    
    }
}
