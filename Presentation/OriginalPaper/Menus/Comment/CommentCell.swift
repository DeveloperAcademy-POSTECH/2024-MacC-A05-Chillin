//
//  CommentCell.swift
//  Reazy
//
//  Created by 김예림 on 11/7/24.
//

import SwiftUI

struct CommentCell: View {
    @EnvironmentObject var pdfViewModel: MainPDFViewModel
    @EnvironmentObject var viewModel: CommentViewModel
    
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
        .padding(.trailing, 16)
        
        Text(comment.text)
            .reazyFont(.text1)
            .foregroundStyle(.point2)
            .padding(.trailing, 16)
        
        HStack{
            Spacer()
            
            Button(action: {
                viewModel.comment = comment
                viewModel.isMenuTapped.toggle()
            }, label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.gray500)
                    .font(.system(size: 24))
            })
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: CommentButtonPositionKey.self, value: geometry.frame(in: .named("OriginalView")).origin)
                }
            )
        }
        .padding(.bottom, 12)
    }
}
