//
//  PaperListView.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI
import Combine

struct PaperListView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @Binding var selectedItemID: UUID?
    @Binding var selectedItems: Set<UUID>
    @State private var isNavigationPushed: Bool = false
    
    @Binding var isEditing: Bool
    @Binding var isEditingTitle: Bool
    @Binding var isEditingFolder: Bool
    @Binding var isEditingMemo: Bool
    @Binding var isEditingFolderMemo: Bool
    
    @State var isFavorite: Bool = false
    @State var selectAll: Bool = false
    
    @Binding var isMovingFolder: Bool
    @State var isPaper: Bool = false
    
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var timerCancellable: Cancellable?
    
    @State private var isIPadMini: Bool = false
    @State private var isVertical = false
    
    // 검색 관련 변수
    @State private var isMenuOpen: Bool = false
    @State private var buttonPosition: CGRect = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        if isEditing {
                            HStack(spacing: 0) {
                                Button(action: {
                                    if selectAll { deselectAllItems() }
                                    else { selectAllItems() }
                                    self.selectAll.toggle()
                                }) {
                                    HStack(spacing: 0) {
                                        if selectAll {
                                            Rectangle()
                                                .frame(width: 22, height: 22)
                                                .foregroundStyle(.clear)
                                                .overlay(
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(.gray600)
                                                )
                                                .padding(.trailing, 8)
                                        } else {
                                            Image(.check)
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 22, height: 22)
                                                .foregroundStyle(.gray600)
                                                .padding(.trailing, 8)
                                        }
                                        
                                        Text(selectAll ? "전체 선택 해제" : "전체 선택")
                                            .reazyFont(.h2)
                                            .foregroundStyle(.gray600)
                                    }
                                }
                                .padding(.vertical, 14)
                                .padding(.leading, 22)
                                
                                Spacer()
                            }
                        } else if homeViewModel.isSearching {
                            searchFilter()
                                .frame(height: 52)
                        } else {
                            HStack(spacing: 0) {
                                // 최상위 폴더가 아닐 경우에 등장
                                if !homeViewModel.isAtRoot {
                                    Button(action: {
                                        withAnimation(nil) {
                                            homeViewModel.navigateToParent()
                                        }
                                    }) {
                                        HStack(spacing: 0) {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.primary1)
                                                .padding(.trailing, 7)
                                            
                                            Text(homeViewModel.parentFolderTitle ?? (homeViewModel.isFavoriteSelected ? "즐겨찾기" : "전체"))
                                                .reazyFont(.h2)
                                                .foregroundStyle(.primary1)
                                        }
                                    }
                                    .transition(.identity)
                                }
                                Spacer()
                                
                                Text((homeViewModel.isAtRoot ? (homeViewModel.isFavoriteSelected ?
                                                                "즐겨찾기" : "전체") : homeViewModel.currentFolder?.title) ?? "새 폴더")
                                .reazyFont(.text3)
                                .foregroundStyle(.primary1)
                                
                                Spacer()
                                if !homeViewModel.isAtRoot {
                                    Button(action: {
                                        isFavorite.toggle()
                                        if let folder = homeViewModel.currentFolder {
                                            homeViewModel.updateFolderFavorite(at: folder.id, isFavorite: isFavorite)
                                        }
                                    }) {
                                        Image(isFavorite ? .starfill : .star)
                                            .renderingMode(.template)
                                            .font(.system(size: 18))
                                            .foregroundStyle(.primary1)
                                    }
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                        }
                        
                        Divider()
                        // MARK: 문인범 2/13
                        if homeViewModel.filteredLists.isEmpty {
                            Spacer()
                            
                            Image(.homePlaceholder)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 146)
                                .padding(.bottom, 11)
                            Text(homeViewModel.isFavoriteSelected ? "즐겨찾기 한 논문이 없어요." : "새로운 논문을 가져와 주세요")
                                .reazyFont(.h5)
                                .foregroundStyle(.gray550)
                                .padding(.bottom, 80)
                            
                            Spacer()
                        } else {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(homeViewModel.filteredLists.indices, id: \.self) { index in
                                        let item = homeViewModel.filteredLists[index]
                                        switch item {
                                            // 논문 추가
                                        case .paper(let paperInfo):
                                            // MARK: searchview 들어갈 위치
                                            PaperListCell(
                                                isPaper: true,
                                                title: paperInfo.title,
                                                date: paperInfo.lastModifiedDate.timeAgo,
                                                color: .gray500,
                                                isSelected: selectedItemID == paperInfo.id,
                                                isEditing: isEditing,
                                                isEditingSelected: selectedItems.contains(item.id),
                                                onSelect: {
                                                    if !isEditing && !isNavigationPushed {
                                                        // 검색 중에 문서를 클릭한다면 바로 이동
                                                        if homeViewModel.isSearching {
                                                            // 검색 후 이동 시 최근 검색어 저장
                                                            homeViewModel.addSearchTerm(homeViewModel.searchText)
                                                            homeViewModel.recentSearches = UserDefaults.standard.recentSearches
                                                            
                                                            selectedItemID = paperInfo.id
                                                        }
                                                        
                                                        if selectedItemID == paperInfo.id {
                                                            self.isNavigationPushed = true
                                                            navigateToPaper()
                                                            homeViewModel.updateLastModifiedDate(at: paperInfo.id, lastModifiedDate: Date())
                                                        } else {
                                                            selectedItemID = paperInfo.id
                                                        }
                                                    }
                                                },
                                                onEditingSelect: {
                                                    if isEditing {
                                                        if selectedItems.contains(item.id) {
                                                            selectedItems.remove(item.id)
                                                        } else {
                                                            selectedItems.insert(item.id)
                                                        }
                                                    }
                                                }
                                            )
                                            
                                            // 폴더 추가
                                        case .folder(let folder):
                                            PaperListCell(
                                                isPaper: false,
                                                title: folder.title,
                                                date: folder.createdAt.timeAgo,
                                                color: FolderColors.color(for: folder.color),
                                                isSelected: selectedItemID == folder.id,
                                                isEditing: isEditing,
                                                isEditingSelected: selectedItems.contains(item.id),
                                                onSelect: {
                                                    if !isEditing && !isNavigationPushed {
                                                        // 검색 중에 폴더를 선택한다면 해당 폴더로 navigate
                                                        if homeViewModel.isSearching {
                                                            // 검색 후 이동 시 최근 검색어 저장
                                                            homeViewModel.addSearchTerm(homeViewModel.searchText)
                                                            homeViewModel.recentSearches = UserDefaults.standard.recentSearches
                                                            
                                                            homeViewModel.isSearching.toggle()
                                                            homeViewModel.selectedMenu = .main
                                                            homeViewModel.searchText = ""
                                                            selectedItemID = folder.id
                                                        }
                                                        
                                                        if selectedItemID == folder.id {
                                                            homeViewModel.navigateTo(folder: folder)
                                                        } else {
                                                            selectedItemID = folder.id
                                                        }
                                                    }
                                                },
                                                onEditingSelect: {
                                                    if isEditing {
                                                        if selectedItems.contains(item.id) {
                                                            selectedItems.remove(item.id)
                                                        } else {
                                                            selectedItems.insert(item.id)
                                                        }
                                                    }
                                                }
                                            )
                                        }
                                        
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundStyle(.primary3)
                                    }
                                }
                            }
                        }
                    }
                    .background(.gray300)
                    
                    // TODO: - [브리] 문서 정보 탭 삭제 예정
//                    if !isEditing && !homeViewModel.isSearching {
//                        Rectangle()
//                            .frame(width: 1)
//                            .foregroundStyle(.primary3)
//                        
//                        VStack(spacing: 0) {
//                            if !homeViewModel.filteredLists.isEmpty,
//                               let selectedItem = homeViewModel.filteredLists.first(where: { $0.id == selectedItemID }) {
//                                switch selectedItem {
//                                case .paper(let paperInfo):
//                                    PaperInfoView(
//                                        id: paperInfo.id,
//                                        image: paperInfo.thumbnail,
//                                        title: paperInfo.title,
//                                        isFavorite: paperInfo.isFavorite,
//                                        isStarSelected: paperInfo.isFavorite,
//                                        isEditingTitle: $isEditingTitle,
//                                        isEditingMemo: $isEditingMemo,
//                                        isMovingFolder: $isMovingFolder,
//                                        onNavigate: {
//                                            if !isEditing && !isNavigationPushed {
//                                                self.isNavigationPushed = true
//                                                navigateToPaper()
//                                            }
//                                        },
//                                        onDelete: {
//                                            if homeViewModel.filteredLists.isEmpty {
//                                                selectedItemID = nil
//                                            } else {
//                                                selectedItemID = homeViewModel.filteredLists.first?.id
//                                            }
//                                        }
//                                    )
//                                    
//                                case .folder(let folder):
//                                    FolderInfoView(
//                                        id: folder.id,
//                                        title: folder.title,
//                                        color: FolderColors(rawValue: folder.color) ?? .folder1,
//                                        isFavorite: folder.isFavorite,
//                                        isStarSelected: folder.isFavorite,
//                                        isEditingFolder: $isEditingFolder,
//                                        isEditingFolderMemo: $isEditingFolderMemo,
//                                        isMovingFolder: $isMovingFolder,
//                                        onNavigate: {
//                                            homeViewModel.navigateTo(folder: folder)
//                                        },
//                                        onDelete: {
//                                            if homeViewModel.filteredLists.isEmpty {
//                                                selectedItemID = nil
//                                            } else {
//                                                selectedItemID = homeViewModel.filteredLists.first?.id
//                                            }
//                                        }
//                                    )
//                                }
//                            }
//                        }
//                        .animation(.easeInOut, value: isEditing)
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background(
//                            LinearGradient(
//                                gradient: Gradient(stops: [
//                                    .init(color: .gray300, location: 0),
//                                    .init(color: Color(hex: "DADBEA"), location: isEditing ? 3.5 : 4)
//                                ]),
//                                startPoint: .top,
//                                endPoint: .bottom
//                            )
//                        )
//                    }
                }
                
                if isMenuOpen {
                    VStack(spacing: 0) {
                        ForEach(SearchFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                self.homeViewModel.selectedFilter = filter
                                withAnimation {
                                    self.isMenuOpen.toggle()
                                }
                            }) {
                                HStack(spacing: 0) {
                                    Text(filter.title)
                                        .reazyFont(.button1)
                                        .foregroundColor(.gray700)
                                    
                                    Spacer()
                                    
                                    // 선택된 항목에만 체크 표시
                                    if homeViewModel.selectedFilter == filter {
                                        Image(.check)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(.primary1)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .frame(width: 156)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.gray100)
                            .shadow(color: Color(hex: "3C3D4B").opacity(0.08), radius: 16, x: 0, y: 0)
                    )
                    .overlay(
                        Image(systemName: "triangle.fill")
                            .resizable()
                            .foregroundStyle(.gray100)
                            .frame(width: 46, height: 30)
                            .offset(x: -30, y: -15),
                        alignment: .top
                    )
                    .position(
                        x: buttonPosition.midX + 46, // 버튼의 중심 X축 위치
                        y: buttonPosition.maxY - 10 // 버튼의 아래 Y축 위치
                    )
                }
            }
            .onAppear {
                initializeSelectedItemID()
                detectIPadMini()
                updateOrientation(with: geometry)
                
                if let folder = homeViewModel.currentFolder {
                    isFavorite = folder.isFavorite
                }
                
                // 키보드 높이에 맞게 검색 Text 위치 조정
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        withAnimation {
                            self.keyboardHeight = keyboardFrame.height
                        }
                    }
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    withAnimation {
                        self.keyboardHeight = 0
                    }
                }
            }
            .onDisappear {
                // Notification 제거
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
                self.isNavigationPushed = false
            }
            .onChange(of: selectedItemID) {
                initializeSelectedItemID()
            }
            .onChange(of: geometry.size) {
                detectIPadMini()
                updateOrientation(with: geometry)
            }
            .onChange(of: homeViewModel.currentFolder) {
                if let folder = homeViewModel.currentFolder {
                    isFavorite = folder.isFavorite
                }
            }
            .onChange(of: selectedItems) {
                if selectedItems.count == homeViewModel.filteredLists.count {
                    self.selectAll = true
                }
            }
            .onChange(of: homeViewModel.selectedFilter) {
                homeViewModel.updateSearchList(with: homeViewModel.selectedFilter)
            }
            .background(.gray200)
            .ignoresSafeArea()
        }
    }
}

extension PaperListView {
    @ViewBuilder
    func searchFilter() -> some View {
        HStack(spacing: 0) {
            GeometryReader { geometry in
                Button(action: {
                    withAnimation {
                        self.isMenuOpen.toggle()
                    }
                    buttonPosition = geometry.frame(in: .global)
                }) {
                    HStack(spacing: 0) {
                        Text(homeViewModel.selectedFilter.title)
                            .reazyFont(.button1)
                            .foregroundStyle(.gray700)
                            .padding(.trailing, 10)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray700)
                    }
                    .padding(.leading, 22)
                    .padding(.vertical, 12)
                }
            }
            .frame(width: 100)
            
            Spacer()
        }
    }
}


extension PaperListView {
    
    // TODO: URL 분리 필요
    private func navigateToPaper() {
        guard let selectedPaperID = selectedItemID,
              let selectedPaper = homeViewModel.paperInfos.first(where: { $0.id == selectedPaperID }) else {
            return
        }
        
        var isStale = false
        let data = selectedPaper.url
        
        guard let url = try? URL.init(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
            print("bookmarkdata to url failed")
            return
        }
        
        if isStale {
            print("Bookmark(\(url.lastPathComponent)) is stale")
            guard let newURL = try? url.bookmarkData(options: .minimalBookmark) else {
                print("Unable to create bookmark")
                return
            }
            
            let idx = homeViewModel.paperInfos.firstIndex { $0.id == selectedPaperID }!
            homeViewModel.paperInfos[idx].url = newURL
        }
        
        if url.startAccessingSecurityScopedResource() {
            navigationCoordinator.push(.mainPDF(paperInfo: selectedPaper))
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func initializeSelectedItemID() {
        if selectedItemID == nil, let firstPaper = homeViewModel.filteredLists.first {
            selectedItemID = firstPaper.id
        }
    }
}

extension PaperListView {
    private func detectIPadMini() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let screenSize = UIScreen.main.nativeBounds.size
            let isMiniSize = (screenSize.width == 1536 && screenSize.height == 2048) ||
            (screenSize.width == 1488 && screenSize.height == 2266)
            self.isIPadMini = isMiniSize
        }
    }
    
    private func updateOrientation(with geometry: GeometryProxy) {
        isVertical = geometry.size.height > geometry.size.width
    }
}

extension PaperListView {
    private func selectAllItems() {
        let allIDs = Set(homeViewModel.filteredLists.map { $0.id })
        selectedItems = allIDs
    }
    
    private func deselectAllItems() {
        selectedItems.removeAll()
    }
}
