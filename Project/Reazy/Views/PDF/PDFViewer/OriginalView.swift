//
//  OriginalView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI
import PDFKit
import Combine

// MARK: - 무니꺼 : 원문 모드 뷰
struct OriginalView: View {
    @EnvironmentObject private var viewModel: MainPDFViewModel
    @EnvironmentObject private var floatingViewModel: FloatingViewModel
    @StateObject var commentViewModel: CommentViewModel
    
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    let publisher = NotificationCenter.default.publisher(for: .isCommentTapped)
    
    var body: some View {
        VStack{
            ZStack {
                VStack(spacing: 0) {
                    OriginalViewControllerRepresent(commentViewModel: commentViewModel) // PDF 뷰를 표시
                    //                    .offset(y: -keyboardResponder.keyboardHeight / 2)
                }
                //            .padding(.bottom, keyboardResponder.keyboardHeight)
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
                        .position(viewModel.isCommentTapped
                                  ? commentViewModel.commentPosition
                                  : viewModel.commentInputPosition )
                        .offset(y: +keyboardResponder.keyboardHeight / 20)
                }
            }
            .animation(.smooth(duration: 0.3), value: viewModel.commentInputPosition)
            .animation(.smooth(duration: 0.1), value: viewModel.isCommentTapped)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onChange(of: viewModel.selectedText) { _, newValue in
                viewModel.updateBubbleView(selectedText: newValue, bubblePosition: viewModel.bubbleViewPosition)
            }.offset(y: commentViewModel.pdfCoordinates.midY > viewModel.commentInputPosition.y
                     ? -keyboardResponder.keyboardHeight / 10
                     : -keyboardResponder.keyboardHeight / 1.2 )
            .animation(.smooth(duration: 0.5), value: keyboardResponder.keyboardHeight)
        }
    }
}

class KeyboardResponder: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    DispatchQueue.main.async {
                        self?.keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.keyboardHeight = 0
                }
            }
            .store(in: &cancellables)
    }
}
