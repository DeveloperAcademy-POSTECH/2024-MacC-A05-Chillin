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
    
    var comment: Comment
    
    var body: some View {
        HStack(alignment: .center){
            Divider()
                .frame(width: 2, height: 14)
                .background(.point4)
                //.padding(.trailing, 6)
            
            if let commentText = comment.selection.string {
                Text(commentText.replacingOccurrences(of: "\n", with: ""))
                    .reazyFont(.body3)
                    .foregroundStyle(.point4)
                    .lineLimit(1)
            }
        }
        .padding(.bottom, 8)
        .padding(.trailing, 16)
        .padding(.top, 18)
        
        Text(comment.text)
            .reazyFont(.body1)
            .foregroundStyle(.point2)
            .padding(.trailing, 16)
        
        HStack{
            Spacer()
            
            Button(action: {
                viewModel.deleteComment(selection: comment.selection, comment: comment)
                pdfViewModel.isCommentTapped = false
            }, label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.gray500)
                    .font(.system(size: 20))
            })
        }
        .padding(.trailing, 9)
        .padding(.bottom, 9)
        
    }
    
}
