//
//  SearchBar.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI

struct SearchBar: View {
    @EnvironmentObject private var homeSearchViewModel: HomeSearchViewModel
    
    var body: some View {
        HStack {
            HStack {
                Image(.search)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.gray600)
                
                TextField("검색", text: $homeSearchViewModel.searchText)
                    .foregroundStyle(.gray600)
                    .onChange(of: homeSearchViewModel.searchText) {
                        // TODO: PDF 들어갔을 때로 수정
                        homeSearchViewModel.searchPapers()
                    }
                
                if !homeSearchViewModel.searchText.isEmpty {
                    Button(action: {
                        homeSearchViewModel.searchText = ""
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                        
                    })
                }
            }
            .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            .foregroundStyle(.secondary)
            .background(.primary2)
            .cornerRadius(10.0)
        }
        .padding(.horizontal)
    }
}

#Preview {
    SearchBar()
}
