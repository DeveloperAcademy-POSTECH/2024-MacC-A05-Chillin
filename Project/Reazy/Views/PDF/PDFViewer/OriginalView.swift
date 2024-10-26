//
//  OriginalView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

// MARK: - 무니꺼 : 원문 모드 뷰
struct OriginalView: View {
    @EnvironmentObject var viewModel: OriginalViewModel
    
    var body: some View {
        ZStack{
            VStack(spacing: 0) {
                OriginalViewControllerRepresent() // PDF 뷰를 표시
            }
            // BubbleView 표시
            if viewModel.isTranslateMode {
                // Show BubbleView if translation mode is active
                if viewModel.bubbleViewVisible {
                    if !viewModel.selectedText.isEmpty {
                        BubbleView(selectedText: viewModel.selectedText, position: viewModel.bubbleViewPosition)
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
