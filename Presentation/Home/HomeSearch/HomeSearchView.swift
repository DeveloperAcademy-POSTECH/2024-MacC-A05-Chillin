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
                            HomePDFCell(paperInfo: paperInfo)
                            
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
                
                DynamicCellLayout(data: items)
                    .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 50)
            .padding(.horizontal, 20)
        }
    }
}

