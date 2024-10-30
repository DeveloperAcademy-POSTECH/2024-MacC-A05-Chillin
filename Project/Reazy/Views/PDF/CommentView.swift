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
        VStack() {
            TextField(
                LocalizedStringKey("AddComment"), text: $text,
                prompt: Text("코멘트 추가").foregroundColor(.primary4)
                ,axis: .vertical
            )
            .foregroundStyle(.point2)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            
            HStack {
                Spacer()
                
                Button(action: {
                    if !text.isEmpty {
                        pdfViewModel.isCommentSaved = true
                        viewModel.addComment(text: text, selection: selection, selectedText: pdfViewModel.selectedText)
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
            .padding(.top, 14)
            .padding(.bottom, 8)
            .padding(.trailing, 12)
        }
        .background(Color.gray200)
        .cornerRadius(12)
        .frame(width: 312)
    }
}
