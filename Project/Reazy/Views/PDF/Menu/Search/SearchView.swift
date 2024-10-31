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
    @EnvironmentObject var mainViewModel: MainPDFViewModel
    
    @StateObject private var viewModel: SearchViewModel = .init()
    
    @State private var searchTimer: Timer?
    @State private var selectedIndex: Int?
    @State private var selectedSelection: PDFSelection?
    
    var body: some View {
        VStack {
            ZStack {
                SearchBoxView()
                
                VStack {
                    SearchTextFieldView(viewModel: viewModel)
                    
                    if !self.viewModel.searchText.isEmpty {
                        SearchTopView(viewModel: viewModel, selectedIndex: $selectedIndex)
                    }
                    
                    SearchListView(viewModel: viewModel, selectedIndex: $selectedIndex, selectedSelection: $selectedSelection)
                }
            }
            .frame(width: 252, height: viewModel.searchText.isEmpty ? 79 : nil)
            .onChange(of: viewModel.searchText) {
                fetchSearchResult()
            }
            .onChange(of: selectedIndex) {
                if viewModel.searchResults.isEmpty { return }
                guard let index = self.selectedIndex else { return }
                
                mainViewModel.searchSelection = viewModel.searchResults[index].selection
                mainViewModel.goToPage(at: viewModel.searchResults[index].page)
            }
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
            }
        }
    }
}

private struct SearchTextFieldView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 232, height: 33)
                .foregroundStyle(.gray200)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14)
                    .padding(.leading, 18)
                    .foregroundStyle(Color(hex: "9092A9"))
                
                TextField("검색", text: $viewModel.searchText)
                    .padding(.trailing, 10)
                    .foregroundStyle(.gray800)
                    .font(.custom(ReazyFontType.pretendardRegularFont, size: 14))
            }
            .frame(width: 252, height: 33)
        }
        .padding(.top, 25)
    }
}

private struct SearchTopView: View {
    @EnvironmentObject var mainViewModel: MainPDFViewModel
    @ObservedObject var viewModel: SearchViewModel
    
    @Binding var selectedIndex: Int?
    
    var body: some View {
        HStack {
            Text("\(viewModel.searchResults.count)개 일치")
                .foregroundStyle(.gray700)
                .font(.custom(ReazyFontType.pretendardRegularFont, size: 12))
            
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
        .padding(12)
    }
    
    private func nextResult() {
        if self.selectedIndex == nil { return }
        
        let count = self.viewModel.searchResults.count
        
        if self.selectedIndex! == count - 1 {
            self.selectedIndex = 0
            return
        }
        
        self.selectedIndex! += 1
    }
    
    private func previousResult() {
        if self.selectedIndex == nil { return }
        
        if self.selectedIndex! == 0 {
            self.selectedIndex = self.viewModel.searchResults.count - 1
            return
        }
        
        self.selectedIndex! -= 1
    }
}


private struct SearchListView: View {
    @EnvironmentObject var mainViewModel: MainPDFViewModel
    
    @ObservedObject var viewModel: SearchViewModel
    @Binding var selectedIndex: Int?
    @Binding var selectedSelection: PDFSelection?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(zip(0 ..< self.viewModel.searchResults.count, self.viewModel.searchResults)), id: \.0) { index, search in
                        VStack(spacing: 0) {
                            SearchListCell(result: search)
                                .onTapGesture {
                                    self.selectedIndex = index
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
                proxy.scrollTo(selectedIndex, anchor: .center)
            }
        }
    }
    
    private var seperator: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(.gray400)
    }
}


extension SearchView {
    private func fetchSearchResult() {
        if viewModel.searchText.isEmpty {
            viewModel.searchResults.removeAll()
            return
        }
        
        guard let document = mainViewModel.document else { return }
        
        if let timer = self.searchTimer {
            timer.invalidate()
        }
        
        self.searchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            viewModel.fetchSearchResults(document: document)
            self.selectedIndex = 0
        }
    }
}
