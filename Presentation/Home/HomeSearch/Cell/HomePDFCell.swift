//
//  HomePDFCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI

struct HomePDFCell: View {
    @State private var popover = false
    @State var paperInfo: PaperInfo
    @Binding var isSelected: Bool
    
    var cellStatus: CellStatus
    let screenWidth: CGFloat
    
    let onTapGesture: () -> Void
    let checkAction: () -> Void
    let starAction: () -> Void
    let tagAction: (UUID) -> Void
    let editAction: () -> Void
    let setTagAction: () -> Void
    let copyAction: () -> Void
    let deleteAction: () -> Void
    let moveAction: () -> Void
    let addTagAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if case .selection = cellStatus {
                    SelectionCheckView(isSelected: isSelected) {
                        isSelected.toggle()
                        checkAction()
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 26)
                }
                
                Button {
                    switch cellStatus {
                    case .normal, .search:
                        onTapGesture()
                    default:
                        break
                    }
                } label: {
                    HStack(alignment: .top, spacing: 0) {
                        ThumbnailImageView(
                            thumbnailData: paperInfo.thumbnail,
                            isStared: paperInfo.isFavorite,
                            starAction: starAction,
                            cellStatus: cellStatus
                        )
                        
                        PaperInformationView(
                            cellStatus: cellStatus,
                            title: paperInfo.title,
                            date: paperInfo.lastModifiedDate,
                            tags: paperInfo.tags,
                            screenWdith: screenWidth,
                            tagAction: tagAction,
                            addAction: addTagAction
                        )
                        
                        Spacer()
                        
                        if case .normal = cellStatus {
                            EllipsisView {
                                popover.toggle()
                            }
                            .popover(isPresented: $popover, arrowEdge: .trailing) {
                                EllipsisButtonView {
                                    editAction()
                                    popover.toggle()
                                } setTagAction: {
                                    setTagAction()
                                    popover.toggle()
                                } copyPaperAction: {
                                    copyAction()
                                    popover.toggle()
                                } deletePaperAction: {
                                    deleteAction()
                                    popover.toggle()
                                } moveFolderAction: {
                                    moveAction()
                                    popover.toggle()
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .frame(height: 138)
            }
            
            Rectangle()
                .foregroundStyle(.primary3)
                .frame(height: 1)
        }
        .background {
            if case .selection = cellStatus, isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.primary2)
                    .padding(.vertical, 6)
                    .padding(.trailing, 12)
            }
        }
    }
}

private struct ThumbnailImageView: View {
    let thumbnailData: Data
    let isStared: Bool
    let starAction: () -> Void
    let cellStatus: CellStatus
    
    var body: some View {
        Image(uiImage: .init(data: thumbnailData) ?? .close)
            .resizable()
            .scaledToFit()
            .frame(width: 82, height: 110)
            .overlay(alignment: .topTrailing) {
                if case .normal = cellStatus {
                    Button {
                        starAction()
                    } label: {
                        Image(isStared ? "starfill" : "star")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(isStared ? .point4 : .gray600)
                    }
                    .padding(6)
                }
            }
    }
}


private struct PaperInformationView: View {
    let cellStatus: CellStatus
    let title: String
    let date: Date
    let tags: [Tag]
    let screenWdith: CGFloat
    
    let tagAction: (UUID) -> Void
    let addAction: () -> Void
    
    @State private var selectedTagY: CGFloat = 0
    @State private var isShowingTags = false
    
    var hiddenTags: [Tag] {
        let shown = Set(getVisibleTags().map { $0.id })
        return tags.filter { !shown.contains($0.id) }
    }
    
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
                if tags.isEmpty, cellStatus == .normal {
                    Button {
                        addAction()
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 26, height: 24)
                            .foregroundStyle(.primary3)
                            .overlay {
                                Image(systemName: "plus")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray800)
                            }
                    }
                } else {
                    ForEach(getVisibleTags()) { tag in
                        PDFTagCell(
                            isMultiSelectable: false,
                            isEditMode: false,
                            tag: tag,
                            selectAction: { tagAction(tag.id) },
                            deleteAction: {}
                        )
                    }
                }
                
                if hiddenTags.count > 0 {
                    Button {
                        isShowingTags = true
                    } label: {
                        Text("+\(hiddenTags.count)")
                            .reazyFont(.body1)
                            .foregroundStyle(.gray800)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .foregroundStyle(.primary3)
                                .preference(key: TagPopoverPositionKey.self, value: geo.frame(in: .global).midY)
                        }
                    )
                    .popover(
                        isPresented: $isShowingTags,
                        attachmentAnchor: .rect(.bounds),
                        arrowEdge: selectedTagY > CGFloat(hiddenTags.count * 38 + 28) ? .top : .bottom
                    ) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(hiddenTags) { tag in
                                PDFTagCell(isMultiSelectable: false,
                                           isEditMode: false,
                                           tag: tag,
                                           selectAction: { tagAction(tag.id) },
                                           deleteAction: {})
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .onPreferenceChange(TagPopoverPositionKey.self) { value in
                            selectedTagY = value
                        }
                    }
                }
            }
            .padding(.bottom, 22)
        }
        .padding(.leading, 20)
    }
    
    private func getVisibleTags() -> [Tag] {
        
        var totalWidth: CGFloat = 0
        var result = [Tag]()
        
        // 가나다, 알파벳 순으로 정렬
        let sortedTags = tags.sorted(by: { $0.name < $1.name })
        
        for tag in sortedTags {
            let width = tag.itemWidth(isEditMode: false)

            if result.count < 6 && totalWidth + width <= screenWdith {
                result.append(tag)
                totalWidth += width
            }
            else if totalWidth + width <= screenWdith + 40 {
                result.append(tag)
                break
            }
            else {
                break
            }
        }
        
        return result
    }
}

// MARK: - Epllipsis 버튼 뷰
private struct EllipsisButtonView: View {
    let editTitleAction: () -> Void
    let setTagAction: () -> Void
    let copyPaperAction: () -> Void
    let deletePaperAction: () -> Void
    let moveFolderAction: () -> Void
    
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
                setTagAction()
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
                moveFolderAction()
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


private struct SelectionCheckView: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.primary1)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.primary4)
            }
        }
    }
}

enum CellStatus {
    case normal
    case selection
    case search
}
