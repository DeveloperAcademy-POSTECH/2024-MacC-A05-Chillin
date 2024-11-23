//
//  SearchWordView.swift
//  Reazy
//
//  Created by 유지수 on 11/23/24.
//

import SwiftUI

struct SearchWordView: View {
    
    // TODO: - 최근 검색어는 10개까지
    // TODO: - 검색어가 길어서 화면을 넘어갈 경우 다음 줄로 이동 (도전 과제)
    @EnvironmentObject private var homeViewModel: HomeViewModel
    let horizontalSpacing: CGFloat = 12
    let verticalSpacing: CGFloat = 12
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("최근 검색한 키워드")
                        .reazyFont(.button1)
                        .foregroundStyle(.gray700)
                    
                    Spacer()
                    
                    Button(action: {
                        homeViewModel.clearAllSearchTerms()
                        homeViewModel.recentSearches = UserDefaults.standard.recentSearches
                    }) {
                        Text("모두 지우기")
                            .reazyFont(.text1)
                            .foregroundStyle(.primary1)
                    }
                    .padding(.trailing, 22)
                }
                .padding(.bottom, 21)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(homeViewModel.recentSearches, id: \.self) { word in
                            SearchWordCell(text: word)
                                .padding(.trailing, 12)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                
                Spacer()
            }
            .padding(.leading, 22)
            .padding(.top, 20)
            .background(.gray300)
        }
    }
}

struct SearchWordCell: View {
    
    @EnvironmentObject private var homeViewModel: HomeViewModel
    let text: String
    
    var body: some View {
        Button(action: {
            homeViewModel.searchText = text
        }) {
            Text(text)
                .reazyFont(.h4)
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.primary3)
                )
        }
    }
}

#Preview {
    SearchWordView()
}
