//
//  TagView.swift
//  Reazy
//
//  Created by 유지수 on 1/27/25.
//

import SwiftUI

// MARK: - [쿠로] 태그 뷰!
struct TagView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    @Namespace private var nsPopover
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.gray300
            
            GeometryReader { geometry in
                VStack(spacing: 1) {
                    HStack {
                        if tagViewModel.isTagSelected {
                            SelectedTagView(selectedTags: $tagViewModel.selectedTags, toggleTag: tagViewModel.tagTapped)
                        } else {
                            TagLEmptyView()
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                tagViewModel.isBtnTapped.toggle()
                            }
                        }, label: {
                            Image(systemName: tagViewModel.isBtnTapped ? "chevron.down" : "chevron.right")
                                .font(.system(size: 16))
                                .foregroundStyle(.gray600)
                        })
                        .frame(alignment: .trailing)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray100)
                            .stroke(Color.gray400, lineWidth: 1)
                    )
                    if tagViewModel.isBtnTapped {
                        VStack {
                            Group {
                                if tagViewModel.isTagExist {
                                    TagListView(selectedTags: $tagViewModel.selectedTags, toggleTag: tagViewModel.tagTapped)
                                } else {
                                    Text("아직 태그를 만들지 않았어요")
                                        .reazyFont(.text1)
                                        .foregroundStyle(.gray550)
                                }
                            }
                            .frame(minHeight: geometry.size.height * 0.35)
                            
                            // 편집 버튼
                            HStack(spacing: 0) {
                                Spacer()
                                if tagViewModel.isEditMode {
                                    Button {
                                        withAnimation {
                                            tagViewModel.isEditMode = false
                                        }
                                    } label: {
                                        Text("완료")
                                            .reazyFont(.button1)
                                            .foregroundColor(.primary1)
                                            .padding(.trailing, 24)
                                            .padding(.bottom, 20)
                                    }
                                } else {
                                    EllipsisView(ellipsisAction: {
                                        withAnimation {
                                            tagViewModel.popover.toggle()
                                        }
                                    })
                                    .matchedGeometryEffect(id: "popover",
                                                           in: nsPopover,
                                                           anchor: .topTrailing)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity,maxHeight: geometry.size.height * 0.4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray200)
                        )
                    }
                }
                .padding([.top, .horizontal], 20)
            }
            if tagViewModel.popover {
                EllipsisButtonView(namespace: nsPopover)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.all)
        .onTapGesture {
            withAnimation {
                tagViewModel.popover = false
            }
        }
    }
}

// MARK: - 태그를 선택하지 않음
struct TagLEmptyView: View {
    var body: some View {
        Text("태그로 원하는 논문을 찾아보세요")
            .reazyFont(.button1)
            .foregroundStyle(.gray550)
//        Spacer()
    }
}

// MARK: - 태그를 선택함
struct SelectedTagView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    @Binding var selectedTags: [String]
    let toggleTag: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(selectedTags.map { Tag(name: $0) }, id: \.id) { tag in
                    SelectedTagCell(tag: tag, action: {
                        toggleTag(tag.name)
                    }, isBtnTapped: tagViewModel.isBtnTapped)
                }
            }
        }
    }
}

// MARK: - 태그 전체 리스트 뷰
struct TagListView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    @Binding var selectedTags: [String]
    let toggleTag: (String) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical){
                DynamicCellLayout(
                    data: tagViewModel.tags,
                    screenWidth: geometry.size.width,
                    selectedTags: tagViewModel.selectedTags,
                    isMultiSelectable: true,
                    isEditMode: tagViewModel.isEditMode,
                    selectAction: { tagName in
                        toggleTag(tagName)
                    },
                    deleteAction: { id in
                        tagViewModel.deleteTag(id: id)
                    }
                )
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }
        }
    }
}

// MARK: - 태그 전체 리스트 뷰
private struct EllipsisButtonView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    tagViewModel.isEditMode = true
                    tagViewModel.popover = false
                }
            } label: {
                HStack {
                    Text("태그 목록 편집")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.editpencil)
                        .resizable()
                        .frame(width: 17, height: 17)
                }
            }
            .foregroundStyle(.gray800)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            .padding(.vertical, 11)
            
            Rectangle()
                .foregroundStyle(.primary2)
                .frame(height: 1)
            
            Button {
                withAnimation {
                    tagViewModel.createTag = true
                    tagViewModel.popover = false
                }
            } label: {
                HStack {
                    Text("새로운 태그 생성")
                        .reazyFont(.body1)
                    Spacer()
                    Image(systemName: "tag")
                        .font(.system(size: 14))
                }
            }
            .foregroundStyle(.gray800)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            .padding(.vertical, 11)
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray100)
                .shadow(color: Color(hex: "#3C3D4B").opacity(0.08),
                        radius: 12, x: 0, y: 0)
        )
        .padding(.trailing, 70)
        .matchedGeometryEffect(id: "popover",
                                in: namespace,
                                properties: .position,
                                anchor: .topTrailing,
                               isSource: false)
    }
}


#Preview {
    TagView()
}
