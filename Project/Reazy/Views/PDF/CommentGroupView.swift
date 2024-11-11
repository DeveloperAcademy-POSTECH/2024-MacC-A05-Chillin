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
        ZStack {
            VStack {
                if pdfViewModel.isCommentTapped {
                    CommentView(viewModel: viewModel, selectedComments: pdfViewModel.selectedComments)
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
        .onChange(of: viewModel.isEditMode) {
            print("editmode")
        }
    }
}

// MARK: - CommentGrouopView 분리

// 저장된 코멘트
private struct CommentView: View {
    @StateObject var viewModel: CommentViewModel
    var selectedComments: [Comment]
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            ForEach(selectedComments.indices, id: \.self) { index in
                CommentCell(viewModel: viewModel, comment: selectedComments[index])
                    .padding(.leading, 16)
                
                if index < selectedComments.count - 1 {
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
                            
                            viewModel.comments[idx] = resultComment
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
                        .font(.system(size: 20))
                })
                .padding(.trailing, 9)
                .disabled(text.isEmpty)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 9)
        .onReceive(self.viewModel.$comment) {
            guard let comment = $0 else { return }
            if viewModel.isEditMode {
                self.text = comment.text
            }
        }
    }
}

// 수정,삭제 뷰

private struct CommentMenuView: View {
    var body: some View {
        HStack{
            Menu {
                Button(action: {
                    //수정 액션
                }, label: {
                    HStack{
                        Image(systemName: "pencil.line")
                            .font(.system(size: 12))
                            .padding(.trailing, 6)
                        Text("수정")
                            .reazyFont(.body3)
                    }
                })
                .foregroundStyle(.gray600)
                
                Button(action: {
                    //수정 액션
                }, label: {
                    HStack{
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .padding(.trailing, 6)
                        Text("삭제")
                            .reazyFont(.body3)
                    }
                }).foregroundStyle(.gray600)
            } label: {
                
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(.gray100)
        .border(.primary2, width: 1)
        .frame(minWidth: 130)
        .cornerRadius(8)
        .shadow(color: Color(hex: "#6E6E6E").opacity(0.25), radius: 10, x: 0, y: 2)
    }
}
