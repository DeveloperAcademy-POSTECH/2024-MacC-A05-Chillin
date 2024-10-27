//
//  OriginalView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

// MARK: - 무니꺼 : 원문 모드 뷰
struct OriginalView: View {
    @EnvironmentObject private var viewModel: MainPDFViewModel
    
    var body: some View {
        ZStack{
            VStack(spacing: 0) {
                OriginalViewControllerRepresent() // PDF 뷰를 표시
            }
            // 번역에 사용되는 말풍선뷰
            if viewModel.isTranslateMode {
                if viewModel.bubbleViewVisible {
                    if !viewModel.selectedText.isEmpty {
                        if #available(iOS 18.0, *) {
                            BubbleView(selectedText: $viewModel.selectedText)
                        } else {
                            // TODO: 이전 버전에서 어떻게 보여줄 지
                        }
                    }
                }
            }
        }
    }
}
    
#Preview {
    OriginalView()
}

extension Notification.Name {
    static let translateModeActivated = Notification.Name("translateModeActivated")
}
