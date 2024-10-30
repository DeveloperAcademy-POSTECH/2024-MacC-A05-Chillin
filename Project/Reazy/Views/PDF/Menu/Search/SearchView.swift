//
//  SearchView.swift
//  Reazy
//
//  Created by 문인범 on 10/29/24.
//

import SwiftUI


/**
 검색 결과 보여주는 View
 */
struct SearchView: View {
    @EnvironmentObject var mainViewModel: MainPDFViewModel
    
    @StateObject private var viewModel: SearchViewModel = .init()
    
    @State private var searchTimer: Timer?
    
    var body: some View {
        VStack {
            ZStack {
                SearchBoxView()
                
                VStack {
                    searchTextFieldView
                    
                    if !self.viewModel.searchText.isEmpty {
                        searchTopView
                    }
                    
                    searchListView
                }
            }
            .frame(width: 252, height: viewModel.searchText.isEmpty ? 79 : nil)
            .onChange(of: viewModel.searchText) {
                fetchSearchResult()
            }
        }
    }
    
    private var searchTextFieldView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 232, height: 33)
                .foregroundStyle(.gray.opacity(0.7))
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .padding(.leading, 18)
                TextField("검색", text: $viewModel.searchText)
            }
            .frame(width: 252, height: 33)
        }
        .padding(.top, 25)
    }
    
    private var searchTopView: some View {
        HStack {
            Text("\(viewModel.searchResults.count)개 일치")
            
            Spacer()
            
            Button {
                
            } label: {
                Image(systemName: "chevron.left")
            }
            
            Button {
                
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(12)
    }
    
    private var searchListView: some View {
        ScrollView {
            VStack {
                ForEach(self.viewModel.searchResults, id: \.self) { search in
                    SearchListCell(result: search)
                }
            }
        }
    }
    
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
        }
    }
}
