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
    @EnvironmentObject private var focusFigureViewModel: FocusFigureViewModel
    
    // 코멘트뷰 위치 관련
    @State private var keyboardOffset: CGFloat = 0
    @State private var pdfViewOffset: CGFloat = 50
    private let screenHeight = UIScreen.main.bounds.height
    
    private let publisher = NotificationCenter.default.publisher(for: .isCommentTapped)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    OriginalViewControllerRepresent(commentViewModel: commentViewModel) // PDF 뷰를 표시
                }
                .offset(y: keyboardOffset == 0 ? 0 : -pdfViewOffset)
                .onReceive(publisher) { a in
                    if let _ = a.userInfo?["hitted"] as? Bool {
                        
                        if commentViewModel.isMenuTapped {          /// 뷰 바깥 영역을 탭했을 때 메뉴가 눌러져 있는 상태이면
                            commentViewModel.isMenuTapped = false   /// 메뉴만 닫히게
                            viewModel.isCommentTapped = true
                        } else {                                    /// 뷰 바깥 영역을 탭했을 때 메뉴가 꺼져있으면
                            viewModel.isCommentTapped = false       /// 코멘트 뷰가 닫히게
                            viewModel.setHighlight(selectedComments: viewModel.selectedComments, isTapped: viewModel.isCommentTapped)
                        }
                    }
                }
                
                // 번역에 사용되는 말풍선뷰
                if viewModel.toolMode == .translate {
                    if #available(iOS 18.0, *) {
                        TranslateView(selectedText: $viewModel.selectedText, translatePosition: $viewModel.translateViewPosition)
                    } else {
                        
                    }
                }
                
                // 코멘트뷰
                    ZStack {
                        if viewModel.isCommentVisible == true || commentViewModel.isEditMode {
                            CommentGroupView(viewModel: commentViewModel, changedSelection: viewModel.commentSelection ?? PDFSelection())
                        }
                    }
                    .position(viewModel.isCommentTapped || commentViewModel.isEditMode ? commentViewModel.commentPosition : viewModel.commentInputPosition)
                    .animation(.smooth(duration: 0.3), value: viewModel.commentInputPosition)
                    .opacity(viewModel.isCommentTapped || viewModel.isCommentVisible || commentViewModel.isEditMode ? 1.0 : 0.0)
                    .animation(.smooth(duration: 0.3), value: viewModel.isCommentTapped || viewModel.isCommentVisible || commentViewModel.isEditMode)
                
                // 코멘트 메뉴
                if let comment = commentViewModel.comment {
                    if commentViewModel.isMenuTapped {
                        let position = commentViewModel.buttonPosition
                        /// 선택된 comment.id와 같은 id 값을 key 로 가지고 있다면
                            .filter {$0.key == comment.id}
                        /// 해당 key의 value를 가져오기 (CGPoint)
                            .map { $0.value }.first
                        if let point = position {
                            ZStack {
                                CommentMenuView(viewModel: commentViewModel, comment: comment)
                            }
                            .position(x: point.x - 30, y: point.y - 110)
                            /// 애니메이션
                            .scaleEffect(commentViewModel.isMenuTapped ? 1.0 : 0.5, anchor: UnitPoint(x: point.x - 30, y: point.y - 110))
                            .opacity(commentViewModel.isMenuTapped ? 1.0 : 0.0)
                        }
                    }
                }
            }
            .offset(y: -keyboardOffset)
            .animation(.smooth(duration: 0.5), value: keyboardOffset)
            .animation(.smooth(duration: 0.3), value: viewModel.isCommentTapped)
            .animation(.smooth(duration: 0.3), value: commentViewModel.isMenuTapped)
            
            // 키보드 열릴 때
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation {
                        if viewModel.isCommentVisible {
                            keyboardOffset = calculateOffset(
                                for: viewModel.commentInputPosition, keyboardFrame: keyboardFrame, screenHeight: geometry.size.height)
                        }
                        if commentViewModel.isEditMode {
                            keyboardOffset = calculateOffset(
                                for: commentViewModel.commentPosition, keyboardFrame: keyboardFrame, screenHeight: geometry.size.height)
                        }
                    }
                }
            }
            // 키보드 닫힐 때
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation {
                    keyboardOffset = 0
                }
            }
        }
    }
    
    // 키보드 offset 계산
    private func calculateOffset(for position: CGPoint, keyboardFrame: CGRect, screenHeight: CGFloat) -> CGFloat {
        let keyboardTopY = screenHeight - keyboardFrame.height
        let margin: CGFloat = 120 // 여유 공간
        
        if position.y + 60 > keyboardTopY {             /// 키보드에 가려질 경우
            return (position.y - keyboardTopY) + margin
        } else {
            return 0                                    /// 키보드에 안 가려짐
        }
    }
}

