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
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    if let currentFolder = homeViewModel.currentFolder {
                        HStack(spacing: 0) {
                            if currentFolder.parentFolderID != nil {
                                Button(action: {
                                    homeViewModel.navigateToParent()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.primary1)
                                }
                                .padding(.leading, 20)
                            }
                            
                            Spacer()
                            
                            Text(currentFolder.title)
                                .reazyFont(.h2)
                                .foregroundStyle(.primary1)
                                .frame(maxWidth: 734)
                            
                            Spacer()
                            
                            if currentFolder.parentFolderID != nil {
                                Rectangle()
                                    .frame(width: 14, height: 34)
                                    .foregroundStyle(.clear)
                                    .padding(.trailing, 20)
                            }
                        }
                        .frame(height: 52)
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.primary3)
                    }
                    
                    HStack(spacing: 0) {
                        if homeViewModel.filteredLists.isEmpty {
                            Spacer()
                            
                            VStack(spacing: 0) {
                                Spacer()
                                
                                Image(.homePlaceholder)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 146)
                                    .padding(.bottom, 11)
                                Text(emptyStateMessage())
                                    .reazyFont(.h5)
                                    .foregroundStyle(.gray550)
                                    .padding(.bottom, 80)
                                
                                Spacer()
                            }
                            
                            Spacer()
                        } else {
                            GeometryReader { geo in
                                VStack(spacing: 0) {
                                    Spacer().frame(height: 6)
                                    
                                    List {
                                        ForEach(homeViewModel.filteredLists, id: \.self) { paperInfo in
                                            HomePDFCell(
                                                paperInfo: paperInfo,
                                                isSelected: Binding(
                                                    get: { homeViewModel.selectedItems.contains(paperInfo.id) },
                                                    set: { newValue in
                                                        if newValue {
                                                            homeViewModel.selectedItems.insert(paperInfo.id)
                                                        } else {
                                                            homeViewModel.selectedItems.remove(paperInfo.id)
                                                        }
                                                    }
                                                ),
                                                cellStatus: homeViewModel.selectedMenu == .edit ? .selection : .normal,
                                                screenWidth: homeViewModel.isPortrait ? geo.size.width * 0.6 :  geo.size.width * 0.7,
                                                onTapGesture: {
                                                    navigateToPaper(paperInfo.id)
                                                    homeViewModel.updateLastModifiedDate(at: paperInfo.id, lastModifiedDate: Date())
                                                },
                                                checkAction: {
                                                    homeViewModel.selectedItems.insert(paperInfo.id)
                                                },
                                                starAction: {
                                                    homeViewModel.updatePaperFavorite(at: paperInfo.id, isFavorite: !paperInfo.isFavorite)
                                                },
                                                tagAction: { _ in },
                                                editAction: {
                                                    homeViewModel.editButtonTapped(paperInfo)
                                                },
                                                setTagAction: {
                                                    homeViewModel.viewStatus = .addTagToPaperInfo(paperInfo)
                                                },
                                                copyAction: { homeViewModel.duplicatePDF(at: paperInfo.id )},
                                                deleteAction: {
                                                    homeViewModel.selectedPaper = paperInfo
                                                    homeViewModel.deleteAlertPresented.toggle()
                                                },
                                                moveAction: {
                                                    homeViewModel.selectedItems.insert(paperInfo.id)
                                                    homeViewModel.isMovingFolder.toggle()
                                                },
                                                addTagAction: {
                                                    homeViewModel.viewStatus = .addTagToPaperInfo(paperInfo)
                                                }
                                            )
                                            .draggable(paperInfo) {
                                                EmptyView()
                                            }
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                            .listRowInsets(EdgeInsets())
                                        }
                                        .padding(.leading, 24)
                                    }
                                    .listStyle(PlainListStyle())
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                }
                                .onAppear(perform: homeViewModel.updatePortrait)
                            }
                        }
                    }
                }
                .background(.gray300)
            }
            .onDisappear {
                homeViewModel.isNavigationPushed = false
            }
            .alert(
                "정말 삭제하시겠습니까?",
                isPresented: $homeViewModel.deleteAlertPresented,
                presenting: homeViewModel.selectedPaper
            ) { paperInfo in
                Button("취소", role: .cancel) {}
                Button("삭제", role: .destructive) {
                    homeViewModel.deletePDF(at: paperInfo.id)
                }
            } message: { paperInfo in
                Text("삭제된 파일은 복구할 수 없습니다.")
            }
            .background(.gray200)
            .ignoresSafeArea()
        }
    }
    
    private func emptyStateMessage() -> String {
        if homeViewModel.isFavoriteSelected {
            return String(localized: "즐겨찾기 한 논문이 없어요")
        } else {
            return String(localized: "새로운 논문을 가져와 주세요")
        }
    }
}

extension PaperListView {
    
    // TODO: URL 분리 필요
    private func navigateToPaper(_ id: UUID) {
        guard let selectedPaper = homeViewModel.paperInfos.first(where: { $0.id == id }) else {
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
            guard let newURL = try? url.bookmarkData(options: .suitableForBookmarkFile) else {
                print("Unable to create bookmark")
                return
            }
            
            let idx = homeViewModel.paperInfos.firstIndex { $0.id == id }!
            homeViewModel.paperInfos[idx].url = newURL
        }
        
        navigationCoordinator.push(.mainPDF(paperInfo: selectedPaper))
    }
}
