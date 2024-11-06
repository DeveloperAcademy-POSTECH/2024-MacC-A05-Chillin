//
//  CommentView.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import SwiftUI
import PDFKit

struct CommentView: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    @State var text: String = ""
    
    @State private var commentHeight: CGFloat = 20 // 초기 높이 설정
    
    let selection: PDFSelection
    
    var body: some View {
        VStack {
            if pdfViewModel.isCommentTapped == true {
                if let comment = viewModel.comments.first(where: { $0.id == pdfViewModel.selectedCommentID }) {
                    
                    VStack(alignment: .leading) {
                        HStack(alignment: .center){
                            Divider()
                                .frame(width: 2, height: 14)
                                .background(.point2)
                                .padding(.trailing, 6)
                            
                            if let commentText = comment.selection.string {
                                Text(commentText.replacingOccurrences(of: "\n", with: ""))
                                    .lineLimit(1)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 9)
                        
                        Text(comment.text)
                        
                        HStack{
                            Spacer()
                            
                            Button(action: {
                                viewModel.deleteComment(selection: selection, comment: comment)
                                pdfViewModel.isCommentTapped = false
                            }, label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(Color(hex: "BABCCF"))
                                    .font(.system(size: 20))
                            })
                            .padding(.trailing, 9)
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.top, 21)
                    .padding(.bottom, 9)
                    .foregroundStyle(.point2)
                }
            } else {
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
                                viewModel.addComment(
                                    pdfView: pdfViewModel.pdfContent?.pdfView ?? PDFView(),
                                    text: text,
                                    selection: selection
                                )
                                text = "" // 코멘트 추가 후 텍스트 필드 비우기
                                dump(viewModel.comments)
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
        }
        .background(Color.gray100)
        .cornerRadius(12)
        .frame(width: 357)
        .border(.primary2, width: 1)
        .shadow(color: Color(hex: "#6E6E6E").opacity(0.25), radius: 10, x: 0, y: 2)
    }
    private func updateCommentHeight() {
        // 텍스트에 맞게 높이 조정
        let lineCount = text.components(separatedBy: "\n").count
        if lineCount < 4 && 1 < lineCount {
            commentHeight = CGFloat(20 + lineCount * 20) // 한 줄당 높이 추가
        }
    }
}

