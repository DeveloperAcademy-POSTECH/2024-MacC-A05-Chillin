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
    @EnvironmentObject var commentViewModel: CommentViewModel
    
    @State private var keyboardOffset: CGFloat = 0
    @State private var cancellables: Set<AnyCancellable> = []
    
    private let publisher = NotificationCenter.default.publisher(for: .isCommentTapped)
    private let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        GeometryReader { geometry in
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
                        .position(viewModel.isCommentTapped
                                  ? commentViewModel.commentPosition
                                  : viewModel.commentInputPosition )
                }
            }
            .offset(y: -keyboardOffset)
            .onAppear {
                
                let screenHeight = geometry.size.height
                
                // 키보드 Notification 설정
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                    .receive(on: DispatchQueue.main)
                    .sink {
                        if let keyboardFrame = $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                            withAnimation {
                                keyboardOffset = calculateOffset(
                                    for: viewModel.commentInputPosition, keyboardFrame: keyboardFrame, screenHeight: screenHeight)
                            }
                        }
                    }
                    .store(in: &cancellables)
                
                NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in
                        withAnimation {
                            keyboardOffset = 0
                        }
                    }
                    .store(in: &cancellables)
            }
            .animation(.smooth(duration: 0.3), value: viewModel.commentInputPosition)
            .animation(.smooth(duration: 0.1), value: viewModel.isCommentTapped)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onChange(of: viewModel.selectedText) { _, newValue in
                viewModel.updateBubbleView(selectedText: newValue, bubblePosition: viewModel.bubbleViewPosition)
            }
            .onDisappear {
                self.cancellables.forEach { $0.cancel() }
            }
        }
    }
    // 키보드 offset 계산
    private func calculateOffset(for position: CGPoint, keyboardFrame: CGRect, screenHeight: CGFloat) -> CGFloat {
        let keyboardTopY = screenHeight - keyboardFrame.height
        let margin: CGFloat = 100 // 여유 공간
        
        // 키보드에 가려질 경우
        if position.y + 50 > keyboardTopY {
            return (position.y - keyboardTopY) + margin
        } else {
            return 0 // 키보드에 안 가려짐
        }
    }
}

