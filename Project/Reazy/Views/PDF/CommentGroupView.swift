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
private struct CommentView: View {
    @StateObject var viewModel: CommentViewModel
    var commentGroup: [Comment]
    
    var comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(commentGroup.indices, id: \.self) { index in
                CommentCell(viewModel: viewModel, comment: commentGroup[index])
                    .padding(.leading, 16)
                
                if index < commentGroup.count - 1 {
                    Divider()
                        .frame(height: 1)
                        .foregroundStyle(.primary2)
                        .padding(0)
                }
            }
        }
        .frame(minWidth: 357, minHeight: 78)
        .foregroundStyle(.point2)
    }
}

// 코멘트 입력 창
private struct CommentInputView: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    
    @State var text: String = ""
    @State private var commentHeight: CGFloat = 20
    
    let changedSelection: PDFSelection
    let placeHolder: Text = .init("코멘트 추가")
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            TextField("\(placeHolder.foregroundStyle(Color.primary4))", text: $text, axis:.vertical)
                .lineLimit(5)
                .reazyFont(.body1)
                .foregroundStyle(.point2)
                .padding(.horizontal, 18)
            
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
                    }
                }, label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(text.isEmpty ? .primary4 : .primary1)
                        .font(.system(size: 20))
                })
                .padding(.trailing, 9)
                .disabled(text.isEmpty)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 9)
    }
}
