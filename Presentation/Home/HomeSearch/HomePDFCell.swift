//
//  HomePDFCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI



struct HomePDFCell: View {
    let paperInfo: PaperInfo
    
    var body: some View {
        Group {
            HStack(alignment: .top, spacing: 0) {
                // TODO: pdf 썸네일
                Image(uiImage: .init(data: paperInfo.thumbnail) ?? .close)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 110)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            
                        } label: {
                            Image(systemName: "star")
                                .font(.system(size: 18))
                                .foregroundStyle(.gray600)
                        }
                        .padding(6)
                    }
                
                
                VStack(alignment: .leading, spacing: 0) {
                    // TODO: pdf 타이틀
                    Text(paperInfo.title)
                        .reazyFont(.text1)
                        .foregroundStyle(.gray900)
                        .padding(.top, 4)
                    
                    // TODO: 수정 날짜
                    Text(paperInfo.lastModifiedDate.timeAgo)
                        .reazyFont(.h4)
                        .foregroundStyle(.gray600)
                        .padding(.top, 6)
                    
                    Spacer()
                    
                    
                    // TODO: 태그 생기면 연결
                    HStack {
                        ForEach(0..<3, id: \.self) { _ in
                            PDFTagCell()
                        }
                    }
                    .padding(.bottom, 22)
                }
                .padding(.leading, 20)
                
                Spacer()
                
                VStack {
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray550)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 10)
        }
        .frame(height: 138)
        .background(.cyan) // TODO: 제거 예정
    }
}


#Preview {
    HomePDFCell(paperInfo: .sampleData)
}
