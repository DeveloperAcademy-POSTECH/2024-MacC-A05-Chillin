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
                        //수정 액션
                        viewModel.comment = comment
                        viewModel.isEditMode = true
                        pdfViewModel.isCommentTapped = false
                    }, label: {
                        VStack(alignment: .center, spacing: 3) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 14))
                            
                            Text("수정")
                                .reazyFont(.h3)
                        }
                    })
                    .foregroundStyle(.gray600)
                    
                    Button(action: {
                        // 삭제 액션
                        viewModel.deleteComment(commentId: comment.id)
                        pdfViewModel.isCommentTapped = false
                        pdfViewModel.setHighlight(selectedComments: pdfViewModel.selectedComments, isTapped: pdfViewModel.isCommentTapped)
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
                .foregroundStyle(.gray100)
                .border(.primary2, width: 1)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.gray500)
                    .font(.system(size: 24))
            }
        }
        .padding([.trailing, .bottom], 12)
    }
}

// 수정,삭제 뷰
struct CommentMenuView: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    var comment: Comment // 선택된 comment
    
    var body: some View {
        HStack{
                Button(action: {
                    //수정 액션
                    viewModel.comment = comment
                    viewModel.isEditMode = true
                    pdfViewModel.isCommentTapped = false
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
                
                Button(action: {
                    viewModel.deleteComment(commentId: comment.id)
                    pdfViewModel.isCommentTapped = false
                    pdfViewModel.setHighlight(selectedComments: pdfViewModel.selectedComments, isTapped: pdfViewModel.isCommentTapped)
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.gray100)
                    .border(.primary2, width: 1)
            )
            .frame(minWidth: 130)
            .shadow(color: Color(hex: "#6E6E6E").opacity(0.25), radius: 10, x: 0, y: 2)
        }
    }

