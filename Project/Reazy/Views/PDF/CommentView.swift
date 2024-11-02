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
    
    let selection: PDFSelection
    
    var body: some View {
        VStack {
            VStack{
                if pdfViewModel.isCommentTapped == true {
                    Text("코멘트뷰어")
                } else {
                    TextField(
                        LocalizedStringKey("AddComment"), text: $text,
                        prompt: Text("코멘트 추가").foregroundColor(.primary4),
                        axis: .vertical
                    )
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .foregroundStyle(.point2)
            HStack {
                Spacer()
                if pdfViewModel.isCommentTapped == true {
                    Button(action: {
                        // 버튼 액션
                    }, label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color(hex: "BABCCF"))
                            .font(.system(size: 20))
                    })
                } else {
                    Button(action: {
                        if !text.isEmpty {
                            pdfViewModel.isCommentSaved = true
                            viewModel.addComment(pdfView: pdfViewModel.pdfContent?.pdfView ?? PDFView(), text: text, selection: selection)
                            text = "" // 코멘트 추가 후 텍스트 필드 비우기
                            dump(viewModel.comments)
                        }
                    }, label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(text.isEmpty ? .primary4 : .point2)
                            .font(.system(size: 20))
                    })
                    .disabled(text.isEmpty)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
            .padding(.trailing, 12)
        }
        .background(Color.gray100)
        .cornerRadius(12)
        .frame(width: 357)
        .border(.primary2, width: 1)
        .shadow(color: Color(hex: "#6E6E6E").opacity(0.25), radius: 10, x: 0, y: 2)
    }
}
