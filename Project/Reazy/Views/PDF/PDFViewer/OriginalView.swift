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
    @State private var showCommentView = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OriginalViewControllerRepresent(commentViewModel: commentViewModel) // PDF 뷰를 표시
            }
            .onTapGesture {
                // 터치 시 말풍선 뷰를 숨기는 처리 추가
                viewModel.updateBubbleView(selectedText: "", bubblePosition: .zero)
                viewModel.isCommentTapped = false
            }
            // 번역에 사용되는 말풍선뷰
            if viewModel.isTranslateMode {
                if viewModel.isBubbleViewVisible {
                    if #available(iOS 18.0, *) {
                        BubbleView(selectedText: $viewModel.selectedText, bubblePosition: $viewModel.bubbleViewPosition)
                        
                    } else {
                        // TODO : 이전 버전 처리
                    }
                }
            }
                if viewModel.isCommentVisible == true {
                    CommentView(viewModel: commentViewModel, selection: viewModel.selection ?? PDFSelection())
                        .position(viewModel.isCommentTapped ? viewModel.commentTappedPosition : viewModel.commentPosition)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
        }
        //.keyboardHeight($keyboardHeight)
        //.offset(y: -keyboardHeight / 1.7)
        .animation(.smooth(duration: 0.5))
        .onChange(of: viewModel.selectedText) { _, newValue in
            viewModel.updateBubbleView(selectedText: newValue, bubblePosition: viewModel.bubbleViewPosition)
        }
    }
}

struct KeyboardProvider: ViewModifier {
    
    var keyboardHeight: Binding<CGFloat>
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification),
                       perform: { notification in
                guard let userInfo = notification.userInfo,
                      let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
                
                self.keyboardHeight.wrappedValue = keyboardRect.height
                
            }).onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification),
                         perform: { _ in
                self.keyboardHeight.wrappedValue = 0
            })
    }
}


public extension View {
    func keyboardHeight(_ state: Binding<CGFloat>) -> some View {
        self.modifier(KeyboardProvider(keyboardHeight: state))
    }
}
