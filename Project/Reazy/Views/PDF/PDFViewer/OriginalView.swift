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
    @EnvironmentObject private var floatingViewModel: FloatingViewModel
    @StateObject var commentViewModel: CommentViewModel
    
    @State private var keyboardHeight: CGFloat = 0
    let publisher = NotificationCenter.default.publisher(for: .isCommentTapped)
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OriginalViewControllerRepresent(commentViewModel: commentViewModel) // PDF 뷰를 표시
            }
            .onReceive(publisher) { a in
                if let _ = a.userInfo?["hitted"] as? Bool {
                    viewModel.isCommentTapped = false
                }
            }
            .onTapGesture {
                // 터치 시 말풍선 뷰를 숨기는 처리 추가
                viewModel.updateBubbleView(selectedText: "", bubblePosition: .zero)
                print("tapped")
                viewModel.isCommentTapped = false
            }
            // 번역에 사용되는 말풍선뷰
            if viewModel.toolMode == .translate {
                if #available(iOS 18.0, *) {
                    if viewModel.isBubbleViewVisible {
                        BubbleView(selectedText: $viewModel.selectedText, bubblePosition: $viewModel.bubbleViewPosition, isPaperViewFirst: $viewModel.isPaperViewFirst)
                            .environmentObject(floatingViewModel)
                            .environmentObject(viewModel)
                    }
                } 
            }
                if viewModel.isCommentVisible == true {
                    CommentGroupView(viewModel: commentViewModel, changedSelection: viewModel.commentSelection ?? PDFSelection())
                        .position(viewModel.isCommentTapped ? commentViewModel.commentPosition : viewModel.commentInputPosition)
                }
        }
        //.keyboardHeight($keyboardHeight)
        //.offset(y: -keyboardHeight / 1.7)
        .animation(.smooth(duration: 0.3), value: viewModel.commentInputPosition)
        .animation(.smooth(duration: 0.1), value: viewModel.isCommentTapped)
        .transition(.move(edge: .bottom).combined(with: .opacity))
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
