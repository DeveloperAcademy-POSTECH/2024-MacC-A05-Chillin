//
//  OriginalView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI
import PencilKit
import PDFKit

// MARK: - 무니꺼 : 원문 모드 뷰
struct OriginalView: View {
    @EnvironmentObject private var viewModel: MainPDFViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OriginalViewControllerRepresent() // PDF 뷰를 표시
            }
            .onTapGesture {
                // 터치 시 말풍선 뷰를 숨기는 처리 추가
                viewModel.updateBubbleView(selectedText: "", bubblePosition: .zero)
            }
            // 번역에 사용되는 말풍선뷰
            if viewModel.toolMode == .translate {
                if viewModel.isBubbleViewVisible {
                    if #available(iOS 18.0, *) {
                        BubbleView(selectedText: $viewModel.selectedText, bubblePosition: $viewModel.bubbleViewPosition)

                    } else {
                        // TODO : 이전 버전 처리
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedText) { _, newValue in
            viewModel.updateBubbleView(selectedText: newValue, bubblePosition: viewModel.bubbleViewPosition)
        }
    }
}
