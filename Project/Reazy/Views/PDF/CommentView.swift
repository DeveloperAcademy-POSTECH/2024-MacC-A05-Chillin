//
//  CommentView.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import SwiftUI
import PDFKit

struct CommentView: View {
    
    @StateObject var commentViewModel: CommentViewModel
    @State var text: String = ""
    
    var body: some View {
        VStack {
            TextField(
                LocalizedStringKey("AddComment"), text: $text,
                prompt: Text("코멘트 추가").foregroundColor(.primary4)
            )
            .foregroundStyle(.point2)
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            
            HStack {
                Spacer()
                
                Button(action: {
                    
                }, label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(text.isEmpty ? .primary4 : .point2)
                        .font(.system(size: 20))
                })
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



#Preview {
    CommentView(commentViewModel: CommentViewModel(comments: []))
}
