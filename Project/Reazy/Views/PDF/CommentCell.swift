//
//  CommentCell.swift
//  Reazy
//
//  Created by 김예림 on 11/7/24.
//

import Foundation
import SwiftUI

struct CommentCell: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @StateObject var viewModel: CommentViewModel
    
    var comment: Comment
    
    var body: some View {
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
                viewModel.deleteComment(selection: comment.selection, comment: comment)
                pdfViewModel.isCommentTapped = false
            }, label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color(hex: "BABCCF"))
                    .font(.system(size: 20))
            })
            .padding(.trailing, 9)
        }
        
    }
    
}
