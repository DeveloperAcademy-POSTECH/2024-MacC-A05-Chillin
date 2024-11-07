//
//  CommentView.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import SwiftUI
import PDFKit

struct CommentGroupView: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    @State var text: String = ""
    
    let changedSelection: PDFSelection
    
    var body: some View {
        VStack {
            if pdfViewModel.isCommentTapped == true {
                if let comment = viewModel.comments.first(where: { $0.id == pdfViewModel.tappedComment?.id }) {
                    CommentView(viewModel: viewModel, commentGroup: viewModel.commentGroup, comment: comment)
                }
            } else {
                CommentInputView(viewModel: viewModel, changedSelection: changedSelection)
            }
        }
        .background(Color.gray100)
        .cornerRadius(12)
        .frame(width: 357)
        .border(.primary2, width: 1)
        .shadow(color: Color(hex: "#6E6E6E").opacity(0.25), radius: 10, x: 0, y: 2)
    }
}

// MARK: - CommentGrouopView 분리

// 저장된 코멘트
struct CommentView: View {
    @StateObject var viewModel: CommentViewModel
    var commentGroup: [Comment]
    
    var comment: Comment
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(commentGroup) { comment in
                CommentCell(viewModel: viewModel, comment: comment)
            }
        }
        .padding(.leading, 16)
        .padding(.top, 21)
        .padding(.bottom, 9)
        .foregroundStyle(.point2)
    }
}

// 코멘트 입력 창
struct CommentInputView: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    
    @State var text: String = ""
    @State private var commentHeight: CGFloat = 20
    
    let changedSelection: PDFSelection
    
    var body: some View {
        VStack(alignment: .leading) {
            TextEditor(text: $text)
                .overlay(alignment: .topLeading) {
                    Text("코멘트 추가")
                        .foregroundStyle(text.isEmpty ? .primary4 : .clear)
                }
                .reazyFont(.h3)
                .foregroundStyle(.point2)
                .frame(height: commentHeight, alignment: .topLeading)
                .padding(.horizontal, 18)
                .onChange(of: text) {
                    // 텍스트가 변경될 때마다 높이 업데이트
                    self.updateCommentHeight()
                }
            
            HStack{
                Spacer()
                
                Button(action: {
                    if !text.isEmpty {
                        pdfViewModel.isCommentSaved = true
                        viewModel.addComment(text: text,
                                             selection: changedSelection
                        )
                        text = "" // 코멘트 추가 후 텍스트 필드 비우기
                        dump(viewModel.comments)
                        //dump(viewModel.commentGroup)
                    }
                }, label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(text.isEmpty ? .primary4 : .point2)
                        .font(.system(size: 20))
                })
                .padding(.trailing, 9)
                .disabled(text.isEmpty)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 9)
    }
    
    private func updateCommentHeight() {
        // 텍스트에 맞게 높이 조정
        let lineCount = text.components(separatedBy: "\n").count
        if lineCount < 4 && 1 < lineCount {
            commentHeight = CGFloat(20 + lineCount * 20) // 한 줄당 높이 추가
        }
    }
}
