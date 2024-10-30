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
    
    var body: some View {
        VStack {
            ZStack {
                SearchBoxView()
                
                VStack {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 232, height: 33)
                            .foregroundStyle(.gray.opacity(0.7))
                        
                        TextField("검색", text: $viewModel.searchText)
                            .frame(width: 232, height: 33)
                    }
                    .padding(.top, 25)
                    
                    Spacer()
                    
                    ScrollView {
                        VStack {
                            ForEach(self.viewModel.searchResults, id: \.self) { search in
                                SearchListCell(result: search)
                                    .frame(width: 230)
                            }
                        }
                    }
                }
            }
            .frame(height: viewModel.searchText.isEmpty ? 79 : nil)
            .onChange(of: viewModel.searchText) {
                // TODO: 입력 후 일정 시간이 지나고 검색이 되게 수정
                guard let document = mainViewModel.document else { return }
                viewModel.fetchSearchResults(document: document)
            }
        }
    }
}
