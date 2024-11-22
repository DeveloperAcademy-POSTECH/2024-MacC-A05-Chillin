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
    @Binding var selectedItems: Set<Int>
    @State private var isNavigationPushed: Bool = false
    
    @Binding var isEditing: Bool
    @Binding var isSearching: Bool
    @Binding var isEditingTitle: Bool
    @Binding var isEditingFolder: Bool
    @Binding var isEditingMemo: Bool
    @Binding var searchText: String
    
    @State var isFavorite: Bool = false
    
    @Binding var isMovingFolder: Bool
    @Binding var isPaper: Bool
    
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var timerCancellable: Cancellable?
    
    @State private var isIPadMini: Bool = false
    @State private var isVertical = false
    
    var filteredLists: [FileSystemItem] {
        if homeViewModel.isFavoriteSelected {
            return homeViewModel.filteringFavList()
        } else {
            return homeViewModel.filteringList()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
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
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.primary1)
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 20)
                    
                    Divider()
                    
                    if filteredLists.isEmpty {
                        if isSearching {
                            Spacer()
                            
                            Text("\"\(searchText)\"와\n일치하는 결과가 없어요")
                                .reazyFont(.h5)
                                .foregroundStyle(.gray600)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, keyboardHeight)
                            
                            Spacer()
                        } else {
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
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(filteredLists.indices, id: \.self) { index in
                                    let item = filteredLists[index]
                                    switch item {
                                        // 논문 추가
                                    case .paper(let paperInfo):
                                        PaperListCell(
                                            isPaper: true,
                                            title: paperInfo.title,
                                            date: timeAgoString(from: paperInfo.lastModifiedDate),
                                            color: .gray500,
                                            isSelected: selectedItemID == paperInfo.id,
                                            isEditing: isEditing,
                                            isEditingSelected: selectedItems.contains(index),
                                            onSelect: {
                                                if !isEditing && !isNavigationPushed {
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
                                                    if selectedItems.contains(index) {
                                                        selectedItems.remove(index)
                                                    } else {
                                                        selectedItems.insert(index)
                                                    }
                                                }
                                            }
                                        )
                                        
                                        // 폴더 추가
                                    case .folder(let folder):
                                        PaperListCell(
                                            isPaper: false,
                                            title: folder.title,
                                            date: timeAgoString(from: folder.createdAt),
                                            color: FolderColors.color(for: folder.color),
                                            isSelected: selectedItemID == folder.id,
                                            isEditing: isEditing,
                                            isEditingSelected: selectedItems.contains(index),
                                            onSelect: {
                                                if !isEditing && !isNavigationPushed {
                                                    if selectedItemID == folder.id {
                                                        homeViewModel.navigateTo(folder: folder)
                                                    } else {
                                                        selectedItemID = folder.id
                                                    }
                                                }
                                            },
                                            onEditingSelect: {
                                                if isEditing {
                                                    if selectedItems.contains(index) {
                                                        selectedItems.remove(index)
                                                    } else {
                                                        selectedItems.insert(index)
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
                .frame(width: {
                    if isEditing || isSearching {
                        return geometry.size.width
                    } else if isIPadMini && isVertical {
                        return geometry.size.width * 0.6
                    } else {
                        return geometry.size.width * 0.7
                    }
                }())
                .background(.gray300)
                
                // 편집 모드 & 검색 모드에서는 문서 정보가 보이지 않아야 함
                if !isEditing && !isSearching {
                    Rectangle()
                        .frame(width: 1)
                        .foregroundStyle(.primary3)
                    
                    VStack(spacing: 0) {
                        if !filteredLists.isEmpty,
                           let selectedItem = filteredLists.first(where: { $0.id == selectedItemID }) {
                            switch selectedItem {
                            case .paper(let paperInfo):
                                PaperInfoView(
                                    isPaper: $isPaper,
                                    id: paperInfo.id,
                                    image: paperInfo.thumbnail,
                                    title: paperInfo.title,
                                    memo: paperInfo.memo,
                                    isFavorite: paperInfo.isFavorite,
                                    isStarSelected: paperInfo.isFavorite,
                                    isEditingTitle: $isEditingTitle,
                                    isEditingMemo: $isEditingMemo,
                                    isMovingFolder: $isMovingFolder,
                                    onNavigate: {
                                        if !isEditing && !isNavigationPushed {
                                            self.isNavigationPushed = true
                                            navigateToPaper()
                                        }
                                    },
                                    onDelete: {
                                        if filteredLists.isEmpty {
                                            selectedItemID = nil
                                        } else {
                                            selectedItemID = filteredLists.first?.id
                                        }
                                    }
                                )
                                
                            case .folder(let folder):
                                FolderInfoView(
                                    isPaper: $isPaper,
                                    id: folder.id,
                                    title: folder.title,
                                    color: FolderColors.color(for: folder.color),
                                    memo: folder.memo,
                                    isFavorite: folder.isFavorite,
                                    isStarSelected: folder.isFavorite,
                                    isEditingFolder: $isEditingFolder,
                                    isEditingMemo: $isEditingMemo,
                                    isMovingFolder: $isMovingFolder,
                                    onNavigate: {
                                        homeViewModel.navigateTo(folder: folder)
                                    },
                                    onDelete: {
                                        if filteredLists.isEmpty {
                                            selectedItemID = nil
                                        } else {
                                            selectedItemID = filteredLists.first?.id
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .animation(.easeInOut, value: isEditing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .gray300, location: 0),
                                .init(color: Color(hex: "DADBEA"), location: isEditing ? 3.5 : 4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
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
            .background(.gray200)
            .ignoresSafeArea()
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
            print("bookmartdata to url failed")
            return
        }
        
        if isStale {
            print("Bookmark(\(url.lastPathComponent)) is stale")
            guard let _ = try? url.bookmarkData(options: .minimalBookmark) else {
                print("Unable to create bookmark")
                return
            }
            // TODO: URL 데이터 업데이트 필요
        }
        
        if url.startAccessingSecurityScopedResource() {
            navigationCoordinator.push(.mainPDF(paperInfo: selectedPaper))
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func initializeSelectedItemID() {
        if selectedItemID == nil, let firstPaper = filteredLists.first {
            selectedItemID = firstPaper.id
        }
    }
}

extension PaperListView {
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "오늘 HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "어제 HH:mm"
            return dateFormatter.string(from: date)
        } else {
            // 이틀 전 이상의 날짜 포맷으로 반환
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy. MM. dd. a h:mm"
            dateFormatter.amSymbol = "오전"
            dateFormatter.pmSymbol = "오후"
            return dateFormatter.string(from: date)
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
