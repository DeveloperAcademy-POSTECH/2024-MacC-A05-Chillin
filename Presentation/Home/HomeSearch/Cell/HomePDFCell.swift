//
//  HomePDFCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI



struct HomePDFCell: View {
    @State private var popover = false
    let paperInfo: PaperInfo
    
    let onTapGesture: () -> Void
    let starAction: () -> Void
    let tagAction: (UUID) -> Void
    let editAction: () -> Void
    let copyAction: () -> Void
    let deleteAction: () -> Void

    
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
                        EllipsisButtonView {
                            editAction()
                            popover.toggle()
                        } copyPaperAction: {
                            copyAction()
                            popover.toggle()
                        } deletePaperAction: {
                            deleteAction()
                            popover.toggle()
                        }
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


// MARK: - Epllipsis 버튼 뷰
private struct EllipsisButtonView: View {
    let editTitleAction: () -> Void
    let copyPaperAction: () -> Void
    let deletePaperAction: () -> Void
    
    // TODO: 버튼 액션 추가
    var body: some View {
        VStack(spacing: 0) {
            Button {
                editTitleAction()
            } label: {
                HStack {
                    Text("제목 수정")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.editpencil)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(.gray800)
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                // TODO: 추후 연결 필요
            } label: {
                HStack {
                    Text("태그 관리")
                        .reazyFont(.body1)
                    Spacer()
                    Image(systemName: "tag")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray800)
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                copyPaperAction()
            } label: {
                HStack {
                    Text("복제")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.copyDark)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(.gray800)
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                // TODO: 추후 연결 필요
            } label: {
                HStack {
                    Text("이동")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.move)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 17, height: 17)
                        .foregroundStyle(.gray800)
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                deletePaperAction()
            } label: {
                HStack {
                    Text("삭제")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.trash)
                        .resizable()
                        .frame(width: 17, height: 17)
                }
            }
            .foregroundStyle(.pen1)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
        }
        .frame(width: 200)
    }
    
    private var divider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(.primary2)
    }
}
