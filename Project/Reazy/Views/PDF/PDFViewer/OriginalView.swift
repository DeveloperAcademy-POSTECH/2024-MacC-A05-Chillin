//
//  OriginalView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI
import PDFKit

// MARK: - 무니꺼 : 원문 모드 뷰
struct OriginalView: View {
    @EnvironmentObject private var viewModel: MainPDFViewModel
    @StateObject private var commentViewModel: CommentViewModel = .init()
    
    var body: some View {
        ZStack{
            VStack(spacing: 0) {
                OriginalViewControllerRepresent() // PDF 뷰를 표시
            }
            // 번역에 사용되는 말풍선뷰
            if viewModel.isTranslateMode {
                if viewModel.isBubbleViewVisible {
                    if #available(iOS 18.0, *) {
                        BubbleView(selectedText: $viewModel.selectedText)
                    }
                }
            }
            
            if viewModel.isCommentVisible {
                CommentView(viewModel: commentViewModel, selection: viewModel.selection ?? PDFSelection())
                    .position(viewModel.commentPosition) // 위치 지정
            }
        }
    }
}

//#Preview {
//    OriginalView(commentViewModel: CommentViewModel)
//}
