//
//  SearchListCell.swift
//  Reazy
//
//  Created by 문인범 on 10/29/24.
//

import SwiftUI


/**
 검색 결과 Cell
 */
struct SearchListCell: View {
    let result: SearchViewModel.SearchResult
    
    
    var body: some View {
        HStack {
            Image(uiImage: result.image)
                .resizable()
                .frame(height: 60)
                .scaledToFit()
            
            VStack {
                HStack {
                    Text("\(result.page)")
                    
                    Spacer()
                    
                    Text("\(result.count)")
                }
                
                Text(result.text)
            }
        }
        .background(.white)
    }
}

#Preview {
    let sample = SearchViewModel.SearchResult(image: .init(systemName: "plus")!, text: "sample입니다", page: 1, count: 10)
    
    SearchListCell(result: sample)
        .frame(width: 300)
}
