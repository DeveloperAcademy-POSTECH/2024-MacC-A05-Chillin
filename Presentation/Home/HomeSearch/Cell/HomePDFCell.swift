//
//  HomePDFCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI



struct HomePDFCell<Content: View>: View {
    @State private var popover = false
    let paperInfo: PaperInfo
    
    let onTapGesture: () -> Void
    let starAction: () -> Void
    let ellipsisButtonView: () -> Content

    
    var body: some View {
            Button {
                onTapGesture()
            } label: {
                HStack(alignment: .top, spacing: 0) {
                    ThumbnailImageView(
                        thumbnailData: paperInfo.thumbnail,
                        isStared: paperInfo.isFavorite
                    ) {
                        
                    }
                    
                    PaperInformationView(
                        title: paperInfo.title,
                        date: paperInfo.lastModifiedDate
                    )
                    
                    Spacer()
                    
                    EllipsisView {
                        popover.toggle()
                    }
                    .popover(isPresented: $popover, arrowEdge: .trailing) {
                        ellipsisButtonView()
                    }
                }
                .padding(.top, 10)
            }
            .frame(height: 138)
    }
}


private struct ThumbnailImageView: View {
    let thumbnailData: Data
    let isStared: Bool
    let starAction: () -> Void
    
    var body: some View {
        Image(uiImage: .init(data: thumbnailData) ?? .close)
            .resizable()
            .scaledToFit()
            .frame(width: 82, height: 110)
            .overlay(alignment: .topTrailing) {
                Button {
                    starAction()
                } label: {
                    Image(systemName: isStared ? "star.fill" :  "star")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray600)
                }
                .padding(6)
            }
    }
}


private struct PaperInformationView: View {
    let title: String
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // TODO: pdf 타이틀
            Text(title)
                .reazyFont(.text1)
                .foregroundStyle(.gray900)
                .padding(.top, 4)
            
            // TODO: 수정 날짜
            Text(date.timeAgo)
                .reazyFont(.h4)
                .foregroundStyle(.gray600)
                .padding(.top, 6)
            
            Spacer()
            
            
            // TODO: 태그 생기면 연결
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    PDFTagCell(tag: TemporaryTag.init(name: "Temporary")) { }
                }
            }
            .padding(.bottom, 22)
        }
        .padding(.leading, 20)
    }
}


private struct EllipsisView: View {
    let ellipsisAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                ellipsisAction()
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray550)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 20)
        }
    }
}


