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
    let tagAction: (UUID) -> Void
    let ellipsisButtonView: () -> Content

    
    var body: some View {
            Button {
                onTapGesture()
            } label: {
                HStack(alignment: .top, spacing: 0) {
                    ThumbnailImageView(
                        thumbnailData: paperInfo.thumbnail,
                        isStared: paperInfo.isFavorite,
                        starAction: starAction
                    )
                    
                    PaperInformationView(
                        title: paperInfo.title,
                        date: paperInfo.lastModifiedDate,
                        tags: paperInfo.tags,
                        tagAction: tagAction
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
                    Image(systemName: isStared ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundStyle(isStared ? .point4 : .gray600)
                }
                .padding(6)
            }
    }
}


private struct PaperInformationView: View {
    let title: String
    let date: Date
    let tags: [Tag]
    
    let tagAction: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .reazyFont(.text1)
                .foregroundStyle(.gray900)
                .lineLimit(1)
                .padding(.top, 4)
            
            Text(date.timeAgo)
                .reazyFont(.h4)
                .foregroundStyle(.gray600)
                .padding(.top, 6)
            
            Spacer()
            
            HStack {
                ForEach(tags) { tag in
                    PDFTagCell(tag: tag) {
                        tagAction(tag.id)
                    }
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


