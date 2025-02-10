//
//  HomePDFCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI



struct HomePDFCell: View {
    var body: some View {
        Group {
            HStack(alignment: .top, spacing: 0) {
                // TODO: pdf 썸네일
                Image(.testThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 110)
                
                
                VStack(alignment: .leading, spacing: 0) {
                    // TODO: pdf 타이틀
                    Text("타이틀 입니다.")
                        .reazyFont(.text1)
                        .foregroundStyle(.gray900)
                        .padding(.top, 4)
                    
                    // TODO: 수정 날짜
                    Text("오늘 12:34")
                        .reazyFont(.h4)
                        .foregroundStyle(.gray600)
                        .padding(.top, 6)
                    
                    Spacer()
                    
                    // TODO: 태그
                    PDFTagCell()
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



struct PDFTagCell: View {
    var body: some View {
        Button {
            
        } label: {
            // TODO: 태그 title
            Text("Reazy")
                .reazyFont(.body1)
                .foregroundStyle(.gray800)
                .frame(height: 24)
                .padding(.horizontal, 8)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(.primary3)
                }
        }
        
    }
}


#Preview {
    HomePDFCell()
}
