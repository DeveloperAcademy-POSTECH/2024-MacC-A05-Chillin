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
    
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("최근 검색한 키워드")
                        .reazyFont(.button1)
                        .foregroundStyle(.gray700)
                    
                    Spacer()
                    
                    if !homeViewModel.recentSearches.isEmpty {
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
                }
                .padding(.bottom, 21)
                
                if homeViewModel.recentSearches.isEmpty {
                    Spacer(minLength: keyboardHeight != 0 ? 100 : 0)
                    
                    Text("최근 검색어가 없습니다")
                        .reazyFont(.h5)
                        .foregroundStyle(.gray550)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, keyboardHeight)
                    
                    Spacer(minLength: keyboardHeight == 0 ? 350 : 0)
                } else {
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
            }
            .padding(.leading, 22)
            .padding(.top, 20)
            .background(.gray300)
            .onAppear {
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
            }
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
                .reazyFont(.h3)
                .foregroundStyle(.gray800)
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
