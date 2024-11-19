//
//  CommentCell.swift
//  Reazy
//
//  Created by 김예림 on 11/7/24.
//

import SwiftUI

struct CommentCell: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    
    var comment: Comment // 선택된 comment
    
    var body: some View {
        HStack(alignment: .center) {
            
            Divider()
                .frame(width: 2, height: 14)
                .background(.point4)
            
            Text(comment.selectedText.replacingOccurrences(of: "\n", with: ""))
                    .reazyFont(.body1)
                    .foregroundStyle(.point4)
                    .lineLimit(1)
        }
        .padding(.bottom, 8)
        .padding(.top, 20)
        
        Text(comment.text)
            .reazyFont(.text1)
            .foregroundStyle(.point2)
            .padding(0)
        
        HStack{
            Spacer()
            Menu {
                ControlGroup {
                    Button(action: {
                        viewModel.comment = comment
                        viewModel.isEditMode = true
                        pdfViewModel.isCommentTapped = false
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
                        viewModel.deleteComment(commentId: comment.id)
                        pdfViewModel.isCommentTapped = false
                        pdfViewModel.setHighlight(selectedComments: pdfViewModel.selectedComments, isTapped: pdfViewModel.isCommentTapped)
                    }, label: {
                        HStack{
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .padding(.trailing, 6)
                            Text("삭제")
                                .reazyFont(.body3)
                        }
                    }).foregroundStyle(.gray600)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.gray500)
                    .font(.system(size: 24))
            }
        }
        .padding([.trailing, .bottom], 12)
    }
}
