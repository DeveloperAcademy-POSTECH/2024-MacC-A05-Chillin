//
//  SearchView.swift
//  Reazy
//
//  Created by 문인범 on 10/29/24.
//

import SwiftUI
import PDFKit


/**
 검색 결과 보여주는 View
 */
struct SearchView: View {    
    @EnvironmentObject private var viewModel: SearchViewModel
    
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    SearchTextFieldView()
                    
                    if !viewModel.searchText.isEmpty && !viewModel.searchResults.isEmpty {
                        SearchTopView()
                        .padding(.top, 3)
                        .padding(.bottom, 10)
                    }
                    
                    
                    if viewModel.isNoMatchTextVisible {
                        Spacer()
                        Spacer()
                        Text("일치하는 결과 없음")
                            .reazyFont(.text5)
                            .foregroundStyle(.gray800)
                            .padding(.bottom, 60)
                        Spacer()
                    }
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    
                    if !viewModel.searchResults.isEmpty {
                        SearchListView()
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, viewModel.isPortrait ? 11 : 16)
            }
            .frame(width: viewModel.isPortrait ? 184 : 252)
            .onAppear {
                viewModel.onAppear()
            }
        }
        .onDisappear {
            viewModel.removeAllAnnotations()
        }
        .background(Color.list)
    }
}

/**
 검색 TextField 뷰
 */
private struct SearchTextFieldView: View {
    @EnvironmentObject private var viewModel: SearchViewModel
    
    @FocusState private var focus: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(.gray200)
            
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .padding(.leading, 8)
                    .foregroundStyle(Color(hex: "9092A9"))
                
                TextField("검색", text: $viewModel.searchText)
                    .padding(.leading, 4)
                    .padding(.trailing, 10)
                    .foregroundStyle(.gray600)
                    .reazyFont(.button3)
                    .focused($focus)
            }
        }
        .frame(height: 33)
        .padding(.top, 20)
    }
}

/**
 검색 결과 상단(검색 결과 갯수, 좌 우 버튼) 뷰
 */
private struct SearchTopView: View {
    @EnvironmentObject private var mainViewModel: MainPDFViewModel
    @EnvironmentObject private var searchViewModel: SearchViewModel
    
    
    var body: some View {
        HStack {
            Text("\(searchViewModel.searchResults.count)개 일치")
                .reazyFont(.text5)
                .foregroundStyle(.gray700)
            
            Spacer()
            
            Button {
                searchViewModel.previousButtonTapped()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray700)
            }
            .padding(.trailing, 16)
            
            Button {
                searchViewModel.nextButtonTapped()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray700)
            }
        }
    }
}

/**
 검색 결과 테이블 뷰
 */
private struct SearchListView: View {
    @EnvironmentObject private var mainViewModel: MainPDFViewModel
    @EnvironmentObject private var searchViewModel: SearchViewModel
    
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(zip(0 ..< self.searchViewModel.searchResults.count, self.searchViewModel.searchResults)), id: \.0) { index, search in
                            SearchListCell(result: search)
                                .onTapGesture {
                                    searchViewModel.searchResultCellTapped(index: index)
                                }
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundStyle(.primary2)
                                        .opacity( searchViewModel.selectedIndex == index ? 1 : 0)
                                }
                                .id(index)
                            seperator
                                .padding(.horizontal, 18)
                    }
                }
            }
            .onChange(of: searchViewModel.selectedIndex) {
                if !searchViewModel.isTapGesture {
                    proxy.scrollTo(searchViewModel.selectedIndex)
                }
            }
        }
    }
    
    private var seperator: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(.gray400)
    }
}

