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
    
    @State private var searchTimer: Timer?
    @State private var selectedIndex: Int?
    @State private var isTapGesture: Bool = false
    @State private var isSearchViewHidden: Bool = false
    
    @FocusState private var focus: Bool
    
    let publisher = NotificationCenter.default.publisher(for: .isSearchViewHidden)
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    SearchTextFieldView(
                        viewModel: viewModel,
                        isSearchViewHidden: $isSearchViewHidden,
                        focus: $focus)
                    
                    if !viewModel.searchText.isEmpty && !viewModel.searchResults.isEmpty {
                        SearchTopView(
                            viewModel: viewModel,
                            isTapGesture: $isTapGesture,
                            selectedIndex: $selectedIndex,
                            focus: $focus)
                    }
                    
                    
                    if viewModel.isNoMatchTextVisible {
                        Spacer()
                        Text("일치하는 결과 없음")
                            .font(.custom(ReazyFontType.pretendardRegularFont, size: 12))
                            .foregroundStyle(.gray800)
                    }
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    
                    if !viewModel.searchResults.isEmpty {
                        SearchListView(
                            viewModel: viewModel,
                            isTapGesture: $isTapGesture,
                            selectedIndex: $selectedIndex,
                            focus: $focus)
                    } else {
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(width: 252)
            .onChange(of: viewModel.searchText) {
                viewModel.isSearched = false
                fetchSearchResult()
            }
            .onChange(of: selectedIndex) {
                if viewModel.searchResults.isEmpty { return }
                guard let index = self.selectedIndex else { return }
                
                viewModel.searchSelection = viewModel.searchResults[index].selection
                viewModel.goToPage(at: viewModel.searchResults[index].page)
            }
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
            }
            .onReceive(publisher) { a in
                if let _ = a.userInfo?["hitted"] as? Bool {
                    self.isSearchViewHidden = true
                }
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
    @ObservedObject var viewModel: SearchViewModel
    
    @Binding var isSearchViewHidden: Bool
    
    var focus: FocusState<Bool>.Binding
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
//                .frame(width: 220, height: 33)
                .foregroundStyle(.gray200)
            
            HStack(spacing: 0) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .padding(.leading, 8)
                    .foregroundStyle(Color(hex: "9092A9"))
                
                TextField("검색", text: $viewModel.searchText) {
                    if $0 {
                        isSearchViewHidden = false
                    }
                }
                .padding(.leading, 4)
                .padding(.trailing, 10)
                .foregroundStyle(.gray800)
                .font(.custom(ReazyFontType.pretendardRegularFont, size: 14))
                .focused(focus)
                .onAppear {
                    focus.wrappedValue = true
                }
                    
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
    @EnvironmentObject var mainViewModel: MainPDFViewModel
    @ObservedObject var viewModel: SearchViewModel
    
    @Binding var isTapGesture: Bool
    @Binding var selectedIndex: Int?
    
    var focus: FocusState<Bool>.Binding
    
    var body: some View {
        HStack {
            Text("\(viewModel.searchResults.count)개 일치")
                .reazyFont(.text5)
                .foregroundStyle(.gray700)
            
            Spacer()
            
            Button {
                previousResult()
            } label: {
                Image(systemName: "chevron.left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9)
                    .foregroundStyle(.gray700)
            }
            .padding(.trailing, 16)
            
            Button {
                nextResult()
            } label: {
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 9)
                    .foregroundStyle(.gray700)
            }
        }
    }
    
    private func nextResult() {
        self.isTapGesture = false
        self.focus.wrappedValue = false
        if self.selectedIndex == nil { return }
        
        let count = self.viewModel.searchResults.count
        
        if self.selectedIndex! == count - 1 {
            self.selectedIndex = 0
            return
        }
        
        self.selectedIndex! += 1
    }
    
    private func previousResult() {
        self.isTapGesture = false
        self.focus.wrappedValue = false
        if self.selectedIndex == nil { return }
        
        if self.selectedIndex! == 0 {
            self.selectedIndex = self.viewModel.searchResults.count - 1
            return
        }
        
        self.selectedIndex! -= 1
    }
}

/**
 검색 결과 테이블 뷰
 */
private struct SearchListView: View {
    @EnvironmentObject var mainViewModel: MainPDFViewModel
    
    @ObservedObject var viewModel: SearchViewModel
    
    @Binding var isTapGesture: Bool
    @Binding var selectedIndex: Int?
    
    var focus: FocusState<Bool>.Binding
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(zip(0 ..< self.viewModel.searchResults.count, self.viewModel.searchResults)), id: \.0) { index, search in
                        LazyVStack(spacing: 0) {
                            SearchListCell(result: search)
                                .onTapGesture {
                                    self.isTapGesture = true
                                    self.selectedIndex = index
                                    focus.wrappedValue = false
                                }
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundStyle(.primary2)
                                        .opacity( selectedIndex == index ? 1 : 0)
                                }
                                .id(index)
                            seperator
                                .padding(.horizontal, 18)
                        }
                    }
                }
            }
            .onChange(of: selectedIndex) {
                if !isTapGesture {
                    proxy.scrollTo(selectedIndex)
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

/**
 뷰모델 업데이트 메소드
 */
extension SearchView {
    private func fetchSearchResult() {
        if viewModel.searchText.isEmpty {
            viewModel.searchResults.removeAll()
            viewModel.isSearched = false
            viewModel.isLoading = false
            return
        }

        guard let document = PDFSharedData.shared.document else { return }
        
        if let timer = self.searchTimer {
            timer.invalidate()
        }
        
        self.searchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            viewModel.removeAllAnnotations()
            viewModel.fetchSearchResults(document: document)
            self.selectedIndex = 0
        }
    }
}
