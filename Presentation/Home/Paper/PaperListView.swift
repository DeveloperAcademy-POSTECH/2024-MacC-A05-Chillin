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
    @StateObject private var paperListViewModel: PaperListViewModel = .init()
    
    @Binding var selectedItemID: UUID?
    @Binding var selectedItems: Set<Int>
    @State private var isFavoritesSelected: Bool = false
    @State private var isNavigationPushed: Bool = false
    
    @Binding var isEditing: Bool
    @Binding var isSearching: Bool
    @Binding var isEditingTitle: Bool
    @Binding var isEditingMemo: Bool
    @Binding var searchText: String
    
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var timerCancellable: Cancellable?
    
    var filteredPaperInfos: [PaperInfo] {
        var infos = isFavoritesSelected
        ? homeViewModel.paperInfos.filter { $0.isFavorite }.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        : homeViewModel.paperInfos.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        
        if !searchText.isEmpty {
            infos = infos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return infos
    }
    
    var filteredLists: [FileSystemItem] {
        let lists = paperListViewModel.sortLists(paperInfos: homeViewModel.paperInfos, folders: homeViewModel.folders)
        return lists
    }
    
    @State private var isIPadMini: Bool = false
    @State private var isVertical = false
    
    var body: some View {
        // 화면 비율에 따라서 리스트 크기 설정 (반응형 UI)
        GeometryReader { geometry in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        
                        Button(action: {
                            isFavoritesSelected = false
                        }, label: {
                            Text("전체 논문")
                                .reazyFont(isFavoritesSelected ? .h2 : .text3)
                                .foregroundStyle(isFavoritesSelected ? .primary4 : .primary1)
                        })
                        
                        Rectangle()
                            .foregroundStyle(.gray500)
                            .frame(width: 1, height: 20)
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            isFavoritesSelected = true
                            // TODO: - 즐겨찾기 filter 적용 필요
                        }, label: {
                            Text("즐겨찾기")
                                .reazyFont(isFavoritesSelected ? .text3 : .h2)
                                .foregroundStyle(isFavoritesSelected ? .primary1 : .primary4)
                        })
                        
                        Spacer()
                    }
                    .padding(.leading, 28)
                    .padding(.vertical, 17)
                    
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
                            
                            Image("empty")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 146)
                                .padding(.bottom, 11)
                            Text("새로운 논문을 가져와주세요")
                                .reazyFont(.h5)
                                .foregroundStyle(.gray550)
                                .padding(.bottom, 80)
                            
                            Spacer()
                        }
                    } else {
                        // MARK: - CoreData
                        if filteredLists.isEmpty {
                            VStack(spacing: 11) {
                                Spacer()
                                Image(.homePlaceholder)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 110)
                                
                                Text("새로운 논문을 가져와주세요")
                                    .reazyFont(.h5)
                                    .foregroundStyle(.gray550.opacity(0.3))
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
                                                color: folder.color,
                                                isSelected: selectedItemID == folder.id,
                                                isEditing: isEditing,
                                                isEditingSelected: selectedItems.contains(index),
                                                onSelect: {
                                                    if !isEditing && !isNavigationPushed {
                                                        if selectedItemID == folder.id {
                                                            // TODO: - 추가 필요
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
                
                // TODO: - [브리] 폴더 시스템 추가 필요
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
                                    id: paperInfo.id,
                                    image: paperInfo.thumbnail,
                                    title: paperInfo.title,
                                    memo: paperInfo.memo,
                                    isFavorite: paperInfo.isFavorite,
                                    isStarSelected: paperInfo.isFavorite,
                                    isEditingTitle: $isEditingTitle,
                                    isEditingMemo: $isEditingMemo,
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
                                    id: folder.id,
                                    title: folder.title,
                                    color: folder.color,
                                    memo: folder.memo,
                                    isFavorite: folder.isFavorite,
                                    isStarSelected: folder.isFavorite,
                                    isEditingTitle: $isEditingTitle,
                                    isEditingMemo: $isEditingMemo,
                                    onNavigate: {
                                        // TODO: - [브리] Folder navigate 코드 작성
                                    },
                                    onDelete: {
                                        // TODO: - [브리] Folder 삭제 코드 작성
                                    }
                                )
                            }
                        }
                        
//                        if !filteredPaperInfos.isEmpty,
//                           let selectedPaperIndex = filteredPaperInfos.firstIndex(where: { $0.id == selectedItemID }) {
//                            PaperInfoView(
//                                id: filteredPaperInfos[selectedPaperIndex].id,
//                                image: filteredPaperInfos[selectedPaperIndex].thumbnail,
//                                title: filteredPaperInfos[selectedPaperIndex].title,
//                                memo: filteredPaperInfos[selectedPaperIndex].memo,
//                                isFavorite: filteredPaperInfos[selectedPaperIndex].isFavorite,
//                                isStarSelected: filteredPaperInfos[selectedPaperIndex].isFavorite,
//                                isEditingTitle: $isEditingTitle,
//                                isEditingMemo: $isEditingMemo,
//                                onNavigate: {
//                                    if !isEditing && !isNavigationPushed {
//                                        self.isNavigationPushed = true
//                                        navigateToPaper()
//                                    }
//                                },
//                                onDelete: {
//                                    if filteredPaperInfos.isEmpty {
//                                        selectedItemID = nil
//                                    } else {
//                                        selectedItemID = filteredPaperInfos.first?.id
//                                    }
//                                }
//                            )
//                        }
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
            .background(.gray200)
            .ignoresSafeArea()
        }
    }
}


extension PaperListView {
    private func navigateToPaper() {
        guard let selectedPaperID = selectedItemID,
              let selectedPaper = homeViewModel.paperInfos.first(where: { $0.id == selectedPaperID }) else {
            return
        }
        
        var isStale = false
        let data = selectedPaper.url
        
        guard let url = try? URL.init(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
            print("bookmartdata to url failed")
            
            if let id = UserDefaults.standard.value(forKey: "sampleId") as? String,
               id == selectedPaperID.uuidString {
                navigationCoordinator.push(.mainPDF(paperInfo: selectedPaper))
                return
            }
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
        let filteredPaperInfos =
        isFavoritesSelected
        ? homeViewModel.paperInfos.filter { $0.isFavorite }.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        : homeViewModel.paperInfos.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        
        if selectedItemID == nil, let firstPaper = filteredPaperInfos.first {
            selectedItemID = firstPaper.id
        }
        
        homeViewModel.paperInfos = filteredPaperInfos
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
