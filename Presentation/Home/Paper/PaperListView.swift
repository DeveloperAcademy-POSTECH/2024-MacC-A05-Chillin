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
    
    @State var isFavorite: Bool = false
    @State var selectAll: Bool = false
    
    @Binding var isMovingFolder: Bool
    @State var isPaper: Bool = false
    
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var timerCancellable: Cancellable?
    
    @State private var isIPadMini: Bool = false
    @State private var isVertical = false
    
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
                }
            }
            .onAppear {
                initializeSelectedItemID()
                detectIPadMini()
                updateOrientation(with: geometry)
            }
            .onDisappear {
                self.isNavigationPushed = false
            }
            .onChange(of: selectedItemID) {
                initializeSelectedItemID()
            }
            .onChange(of: geometry.size) {
                detectIPadMini()
                updateOrientation(with: geometry)
            }
            .onChange(of: selectedItems) {
                if selectedItems.count == homeViewModel.filteredLists.count {
                    self.selectAll = true
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
