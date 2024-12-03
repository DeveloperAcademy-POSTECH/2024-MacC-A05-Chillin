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
    @EnvironmentObject var viewModel: CommentViewModel
    @State var text: String = ""
    
    let changedSelection: PDFSelection
    
    var body: some View {
        ZStack {
            VStack {
                if pdfViewModel.isCommentTapped {
                    CommentView(selectedComments: pdfViewModel.selectedComments)
                } else {
                    CommentInputView(viewModel: viewModel, changedSelection: changedSelection)
                }
            }
            .frame(maxWidth: 386, minHeight: 91)
            .background(Color.gray100)
            .border(.primary2, width: 1)
            .cornerRadius(16)
            .shadow(color: Color(hex: "#6E6E6E").opacity(0.25), radius: 10, x: 0, y: 2)
        }
        .onChange(of: viewModel.isEditMode) {
            print("editmode")
        }
    }
}


// MARK: - 저장된 코멘트 뷰
private struct CommentView: View {
    var selectedComments: [Comment]
    
    var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(selectedComments.indices, id: \.self) { index in
                    CommentCell(comment: selectedComments[index])
                        .padding(.leading, 22)
                        .padding(.trailing, 12)
                    
                    if index < selectedComments.count - 1 {
                        Divider()
                            .frame(height: 1)
                            .foregroundStyle(.primary2)
                            .padding(0)
                    }
                }
            }
            .foregroundStyle(.point2)        
    }
}

// MARK: -  코멘트 입력 창
private struct CommentInputView: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    
    @State var text: String = ""
    @State private var commentHeight: CGFloat = 20
    
    let changedSelection: PDFSelection
    let placeHolder: Text = .init("코멘트 추가")
    
    var body: some View {
        VStack(alignment: .leading) {
            TextField(
                "\(placeHolder.foregroundStyle(Color.primary4))",
                text: $text, axis:.vertical
            )
            .lineLimit(4)
            .reazyFont(.text1)
            .foregroundStyle(.point2)
            .padding(.horizontal, 22)
            .padding(.vertical, 5)
            
            HStack{
                Spacer()
                
                Button(action: {
                    
                    defer {
                        viewModel.isEditMode = false
                    }
                    pdfViewModel.isCommentTapped = false
                    pdfViewModel.setHighlight(selectedComments: pdfViewModel.selectedComments, isTapped: pdfViewModel.isCommentTapped)
                    
                    if !text.isEmpty {
                        if viewModel.isEditMode {
                            guard let commentId = viewModel.comment?.id else {return}
                            let comments = viewModel.comments
                            guard let idx = viewModel.comments.firstIndex(where: { $0.id == commentId }) else { return }
                            
                            let resultComment = Comment(
                                id: comments[idx].id,
                                buttonId: comments[idx].buttonId,
                                text: self.text,
                                selectedText: comments[idx].selectedText,
                                selectionsByLine: comments[idx].selectionsByLine,
                                pages: comments[idx].pages,
                                bounds: comments[idx].bounds)
                            
                            _ = viewModel.commentService.editCommentData(for: viewModel.paperInfo.id, with: resultComment)
                            viewModel.comments[idx] = resultComment
                            viewModel.tempCommentArray[idx] = resultComment
                            return
                        }
                        pdfViewModel.isCommentSaved = true
                        viewModel.addComment(text: text,
                                             selection: changedSelection
                        )
                        text = "" // 코멘트 추가 후 텍스트 필드 비우기
                    }
                    viewModel.isEditMode = false
                }, label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(text.isEmpty ? .primary4 : .primary1)
                        .font(.system(size: 28))
                })
                .padding([.trailing,.bottom], 12)
                .disabled(text.isEmpty)
            }
        }
        .padding(.top, 18)
        .onReceive(self.viewModel.$comment) {
            guard let comment = $0 else { return }
            if viewModel.isEditMode {
                self.text = comment.text
            }
        }
    }
}

// MARK: - 수정,삭제 뷰
struct CommentMenuView: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @EnvironmentObject var viewModel: CommentViewModel
    var comment: Comment    /// 선택된 comment
    
    var body: some View {
        HStack{
            
            // 수정
            Button(action: {
                viewModel.isEditMode = true
                pdfViewModel.isCommentTapped = false
                viewModel.isMenuTapped = false
            }, label: {
                VStack(alignment: .center, spacing: 3) {
                    Image(systemName: "pencil.line")
                        .font(.system(size: 14))
                    
                    Text("수정")
                        .reazyFont(.h3)
                }
            })
            .foregroundStyle(.gray600)
            
            Divider().frame(width: 1, height: 43)
                .tint(.primary2)
                .padding(.horizontal, 33)
            
            // 삭제
            Button(action: {
                viewModel.deleteComment(commentId: comment.id)
                pdfViewModel.isCommentTapped = false
                pdfViewModel.setHighlight(selectedComments: pdfViewModel.selectedComments, isTapped: pdfViewModel.isCommentTapped)
                viewModel.isMenuTapped = false
            }, label: {
                VStack(alignment: .center, spacing: 3) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                    
                    Text("삭제")
                        .reazyFont(.h3)
                }
            })
            .foregroundStyle(.gray600)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 15)
        .background(.gray100)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.primary2, lineWidth: 1)
        )
        .frame(minWidth: 180, minHeight: 67)
        .shadow(color: Color(hex: "#6E6E6E").opacity(0.25), radius: 10, x: 0, y: 2)
    }
}

