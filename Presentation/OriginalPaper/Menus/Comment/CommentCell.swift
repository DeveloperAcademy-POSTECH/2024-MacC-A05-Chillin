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
    
    @State var comment: Comment // 선택된 comment
    
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
                    /// 탭했을 때 누른 버튼의 위치 값을 가져와야 함
                    .onChange(of: viewModel.isMenuTapped) {
                        let position = geometry.frame(in: .global).origin
                        /// 버튼 위치를 comment의 id와 함께 저장하기
                        viewModel.buttonPosition[comment.id] = position
                    }
                    .onDisappear {
                        /// 초기화
                        viewModel.buttonPosition = [:]
                    }
                }
            )
        }
        .padding(.bottom, 12)
    }
}
