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
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Button {
                    homeSearchViewModel.searchTargetChanged(target: .title)
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
                    homeSearchViewModel.searchTargetChanged(target: .tag)
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
                    VStack(spacing: 0) {
                        ForEach(homeSearchViewModel.searchList) { paperInfo in
                            HomePDFCell(paperInfo: paperInfo) {
                                // TODO: 네비게이션 push 시 Date 업데이트 필요
                                homeSearchViewModel.setRecentSearchList()
                                navigationCoordinator.push(.mainPDF(paperInfo: paperInfo))
                            } starAction: {
                                // TODO: 즐겨찾기
                            } ellipsisButtonView: {
                                EllipsisButtonView()
                            }
                            
                            
                            Rectangle()
                                .foregroundStyle(.primary3)
                                .frame(height: 1)
                        }
                        .padding(.leading, 30)
                    }
                }
            }
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



// MARK: - Epllipsis 버튼 뷰
private struct EllipsisButtonView: View {
    // TODO: 버튼 액션 추가
    var body: some View {
        VStack(spacing: 0) {
            Button {
                
            } label: {
                HStack {
                    Text("제목 수정")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.editpencil)
                        .resizable()
                        .frame(width: 17, height: 17)
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                
            } label: {
                HStack {
                    Text("태그 관리")
                        .reazyFont(.body1)
                    Spacer()
                    Image(systemName: "tag")
                        .font(.system(size: 14))
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                
            } label: {
                HStack {
                    Text("복제")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.copyDark)
                        .resizable()
                        .frame(width: 17, height: 17)
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                
            } label: {
                HStack {
                    Text("이동")
                        .reazyFont(.body1)
                    Spacer()
                    Image(.move)
                        .resizable()
                        .frame(width: 17, height: 17)
                }
            }
            .foregroundStyle(.gray800)
            .frame(height: 40)
            .padding(.leading, 17)
            .padding(.trailing, 14)
            divider
            
            Button {
                
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


// MARK: - 검색 히스토리 뷰
private struct RecentlySearchedKeywordView: View {
    @EnvironmentObject private var homeSearchViewModel: HomeSearchViewModel
    
    // MARK: 샘플 데이터
    let items: [TemporaryTag] = {
        var result = [TemporaryTag]()
        
        for i in 0 ..< 20 {
            result.append(.init(name: .init(repeating: "a", count: i)))
        }
        
        return result
    }()
    
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
                        homeSearchViewModel.removeAllRecentSearches()
                    }
                    .reazyFont(.text1)
                    .foregroundStyle(.primary1)
                }
                
                DynamicCellLayout(data: homeSearchViewModel.recentSearches) { title in
                    homeSearchViewModel.cellTapped(title: title)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)
        }
    }
}

