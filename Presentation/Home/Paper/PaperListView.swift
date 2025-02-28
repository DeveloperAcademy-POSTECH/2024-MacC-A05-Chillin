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
                    if homeViewModel.filteredLists.isEmpty {
                        Spacer()
                        
                        VStack(spacing: 0) {
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
                        
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                Spacer().frame(height: 6)
                                
                                ForEach(homeViewModel.filteredLists, id: \.self) { paperInfo in
                                    // MARK: searchview 들어갈 위치
                                    HomePDFCell(
                                        paperInfo: paperInfo,
                                        onTapGesture: {
                                            navigateToPaper(paperInfo.id)
                                            homeViewModel.updateLastModifiedDate(at: paperInfo.id, lastModifiedDate: Date())
                                        },
                                        starAction: {
                                            homeViewModel.updatePaperFavorite(at: paperInfo.id, isFavorite: !paperInfo.isFavorite)
                                        },
                                        tagAction: { _ in },
                                        editAction: {
                                            homeViewModel.editButtonTapped(paperInfo)
                                        },
                                        copyAction: { homeViewModel.duplicatePDF(at: paperInfo.id )},
                                        deleteAction: { homeViewModel.deletePDF(at: paperInfo.id) }
                                    )
                                    
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundStyle(.primary3)
                                }
                                .padding(.leading, 24)
                            }
                        }
                    }
                }
                .background(.gray300)
            }
            .onAppear {
                detectIPadMini()
                updateOrientation(with: geometry)
            }
            .onDisappear {
                self.isNavigationPushed = false
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
            guard let newURL = try? url.bookmarkData(options: .minimalBookmark) else {
                print("Unable to create bookmark")
                return
            }
            
            let idx = homeViewModel.paperInfos.firstIndex { $0.id == id }!
            homeViewModel.paperInfos[idx].url = newURL
        }
        
        if url.startAccessingSecurityScopedResource() {
            navigationCoordinator.push(.mainPDF(paperInfo: selectedPaper))
            url.stopAccessingSecurityScopedResource()
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
