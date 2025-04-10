//
//  HomeSearchView.swift
//  Reazy
//
//  Created by 문인범 on 2/12/25.
//

import SwiftUI


struct HomeSearchView: View {
    @EnvironmentObject private var homeSearchViewModel: HomeSearchViewModel
    
    var body: some View {
        if !homeSearchViewModel.searchText.isEmpty {
            HomeSearchListView()
        } else {
            RecentlySearchedKeywordView()
        }
    }
}


// MARK: - 검색 결과 뷰
private struct HomeSearchListView: View {
    @EnvironmentObject private var homeSearchViewModel: HomeSearchViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var deleteAlertPresented: Bool = false
    @State private var selectedPaper: PaperInfo?
    @State private var isPortrait: Bool = false
    
    let publisher = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Button {
                    homeSearchViewModel.searchTargetButtonTapped(target: .title)
                } label: {
                    Text("제목")
                        .reazyFont(.button1)
                        .foregroundStyle(
                            homeSearchViewModel.searchTarget == .title ? .primary1 : .gray550
                        )
                        .padding(.leading, 30)
                        .padding(.trailing, 20)
                }
                
                Button {
                    homeSearchViewModel.searchTargetButtonTapped(target: .tag)
                } label: {
                    Text("태그")
                        .reazyFont(.button1)
                        .foregroundStyle(
                            homeSearchViewModel.searchTarget == .tag ? .primary1 : .gray550
                        )
                        .padding(.leading, 20)
                        .padding(.vertical, 20)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            
            if homeSearchViewModel.searchList.isEmpty, !homeSearchViewModel.isLoading {
                Spacer()
                SearchResultEmptyView(text: homeSearchViewModel.searchText)
                Spacer()
            } else {
                ScrollView {
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            ForEach(homeSearchViewModel.searchList) { paperInfo in
                                HomePDFCell(paperInfo: paperInfo, cellStatus: .search, screenWidth: isPortrait ? geometry.size.width * 0.7 :  geometry.size.width * 0.8) {
                                    // TODO: 네비게이션 push 시 Date 업데이트 필요
                                    homeSearchViewModel.PaperCellTapped(paperInfo)
                                    navigationCoordinator.push(.mainPDF(paperInfo: paperInfo))
                                } checkAction: {
                                    homeViewModel.selectedItems.insert(paperInfo.id)
                                } starAction: {
                                    homeSearchViewModel.starButtonTapped(paperInfo)
                                } tagAction: { id in
                                    homeSearchViewModel.tagTapped(id)
                                } editAction: {
                                    homeSearchViewModel.editButtonTapped(paperInfo)
                                } setTagAction: {
                                    homeSearchViewModel.setTagButtonTapped(paperInfo)
                                } copyAction: {
                                    homeSearchViewModel.copyButtonTapped(paperInfo)
                                } deleteAction: {
                                    selectedPaper = paperInfo
                                    deleteAlertPresented.toggle()
                                } moveAction: {
                                    homeViewModel.selectedItems.insert(paperInfo.id)
                                    homeViewModel.isMovingFolder.toggle()
                                }
                                .padding(.leading, 30)
                            }
                        }
                    }
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
        .alert("정말 삭제하시겠습니까?", isPresented: $deleteAlertPresented) {
            Button("삭제", role: .destructive) {
                if let paperInfo = selectedPaper {
                    homeSearchViewModel.deleteButtonTapped(paperInfo)
                }
            }
            
            Button("취소", role: .cancel, action: {})
        }
    }
}


private struct SearchResultEmptyView: View {
    let text: String
    
    var body: some View {
        Text("\"\(text)\"와\n일치하는 결과가 없어요")
            .reazyFont(.h5)
            .foregroundStyle(.gray550)
            .multilineTextAlignment(.center)
    }
}


// MARK: - 검색 히스토리 뷰
private struct RecentlySearchedKeywordView: View {
    @EnvironmentObject private var homeSearchViewModel: HomeSearchViewModel
    
    var body: some View {
        if homeSearchViewModel.recentSearches.isEmpty {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("최근 검색한 키워드가 없어요")
                        .reazyFont(.h5)
                        .foregroundStyle(.gray550)
                    Spacer()
                }
                Spacer()
            }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("최근 검색한 키워드")
                        .reazyFont(.button1)
                        .foregroundStyle(.gray700)
                    Spacer()
                    
                    Button("모두 지우기") {
                        homeSearchViewModel.removeAllButtonTapped()
                    }
                    .reazyFont(.text1)
                    .foregroundStyle(.primary1)
                }
                
                DynamicCellLayout(data: homeSearchViewModel.recentSearches,
                                  screenWidth: UIScreen.main.bounds.width,
                                  isMultiSelectable: false,
                                  isEditMode: false,
                                  selectAction: { title in
                    homeSearchViewModel.cellTapped(title: title)
                }, deleteAction: {_ in })
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)
        }
    }
}

