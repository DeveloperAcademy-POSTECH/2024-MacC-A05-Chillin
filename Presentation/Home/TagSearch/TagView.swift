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
                .onTapGesture {
                    withAnimation {
                        tagViewModel.isBtnTapped = false
                        tagViewModel.popover = false
                    }
                }
            
            if (tagViewModel.tagFilteredPapers.isEmpty) {
                EmptyPaperListView()
            } else {
                FilteredPaperListView()
                    .padding(.top, 92)
            }
            
            GeometryReader { geometry in
                VStack(spacing: 1) {
                    Button(action: {
                        withAnimation {
                            tagViewModel.isBtnTapped.toggle()
                        }
                    }, label: {
                        HStack {
                            if tagViewModel.isTagSelected {
                                SelectedTagView(selectedTags: tagViewModel.selectedTags)
                            } else {
                                TagEmptyView()
                            }
                            
                            Spacer()
                            
                            Image(systemName: tagViewModel.isBtnTapped ? "chevron.down" : "chevron.right")
                                .font(.system(size: 16))
                                .foregroundStyle(.gray600)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray100)
                                .stroke(Color.gray400, lineWidth: 1)
                        )
                    })
                    
                    if tagViewModel.isBtnTapped {
                        LazyVStack(alignment: .center, spacing: 0) {
                            VStack {
                                if tagViewModel.isTagExist {
                                    TagListView()
                                } else {
                                    Text("아직 태그를 만들지 않았어요")
                                        .reazyFont(.text1)
                                        .foregroundStyle(.gray550)
                                }
                            }
                            .padding(.top, 24)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: geometry.size.width - 40, minHeight: geometry.size.height * 0.33)
                            
                            
                            // 편집 버튼
                            HStack(spacing: 0) {
                                Spacer()
                                if tagViewModel.isEditMode {
                                    Button {
                                        withAnimation(.easeInOut) {
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
                        .frame(maxHeight: geometry.size.height * 0.4)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.gray200)
                        )
                    }
                }
                .padding([.top, .horizontal], 20)
                .onAppear(){
                    tagViewModel.getlistWidth(width: geometry.size.width)
                }
                .onChange(of: geometry.size.width) {
                    tagViewModel.getlistWidth(width: geometry.size.width)
                }
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
        .onAppear {
            tagViewModel.onAppear()
        }
    }
}

// MARK: - 태그를 선택하지 않음
struct TagEmptyView: View {
    var body: some View {
        Text("태그로 원하는 논문을 찾아보세요")
            .reazyFont(.button1)
            .foregroundStyle(.gray550)
    }
}

// MARK: - 태그를 선택함
struct SelectedTagView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    var selectedTags: [Tag]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(selectedTags) { tag in
                    SelectedTagCell(tag: tag, action: {
                        tagViewModel.tagTapped(for: tag.name)
                    }, isBtnTapped: tagViewModel.isBtnTapped)
                }
            }
        }
    }
}

// MARK: - 태그 전체 리스트 뷰
struct TagListView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                DynamicCellLayout(
                    data: tagViewModel.tags,
                    screenWidth: tagViewModel.listWidth,
                    isMultiSelectable: true,
                    isEditMode: tagViewModel.isEditMode,
                    selectAction: { tagName in
                        tagViewModel.tagTapped(for: tagName)
                    },
                    deleteAction: { id in
                        tagViewModel.showDeleteAlert(id: id)
                    }
                )
            }
        }
        .onAppear {
            tagViewModel.fetchTags()
        }
    }
}

// MARK: - 편집메뉴
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

private struct EmptyPaperListView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(.tagfill)
            Text("원하는 논문을 태그로 찾아보세요")
                .reazyFont(.h5)
                .foregroundColor(.gray550)
            Spacer()
        }
    }
}

private struct FilteredPaperListView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    @State private var deleteAlertPresented: Bool = false
    @State private var selectedPaper: PaperInfo?
    @State private var isPortrait: Bool = false
    
    let publisher = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    ForEach(tagViewModel.tagFilteredPapers, id: \.self) { paperInfo in
                        HomePDFCell(
                            paperInfo: paperInfo,
                            isSelected: .constant(false),
                            cellStatus: homeViewModel.selectedMenu == .edit ? .selection : .normal,
                            screenWidth: isPortrait ? geometry.size.width * 0.6 :  geometry.size.width * 0.73,
                            onTapGesture: {
                                navigationCoordinator.push(.mainPDF(paperInfo: paperInfo))
                            },
                            checkAction: {
                                homeViewModel.selectedItems.insert(paperInfo.id)
                            },
                            starAction: {
                                tagViewModel.starButtonTapped(paperInfo: paperInfo)
                            },
                            tagAction: { _ in },
                            editAction: {
                                homeViewModel.viewStatus = .search(paperInfo)
                            },
                            setTagAction: {
                                // TODO: 뭐 들어가야 함?
                                homeViewModel.viewStatus = .addTagToPaperInfo(paperInfo)
                            },
                            copyAction: {
                                tagViewModel.copyButtonTapped(paperInfo: paperInfo)
                            },
                            deleteAction: {
                                selectedPaper = paperInfo
                                deleteAlertPresented.toggle()
                            },
                            moveAction: {
                                homeViewModel.selectedItems.insert(paperInfo.id)
                                homeViewModel.isMovingFolder.toggle()
                            },
                            addTagAction: {
                                homeViewModel.viewStatus = .addTagToPaperInfo(paperInfo)
                            }
                        )
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .padding(.leading, 24)
        .alert("정말 삭제하시겠습니까?", isPresented: $deleteAlertPresented) {
            Button("삭제", role: .destructive) {
                if let paperInfo = selectedPaper {
                    tagViewModel.deleteButtonTapped(paperInfo: paperInfo)
                }
            }
            
            Button("취소", role: .cancel, action: {})
        }
        .onAppear {
            if UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown {
                self.isPortrait = true
            }
        }
        .onReceive(publisher) { noti in
            let currentOrientation = UIDevice.current.orientation
            
            switch currentOrientation {
            case .portrait, .portraitUpsideDown:
                self.isPortrait = true
            case .landscapeLeft, .landscapeRight:
                self.isPortrait = false
            default:
                break
            }
        }
    }
}


#Preview {
    TagView()
}
