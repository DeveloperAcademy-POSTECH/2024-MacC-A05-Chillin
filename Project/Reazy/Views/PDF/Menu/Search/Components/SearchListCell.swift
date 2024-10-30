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
            Text(result.text)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .padding(12)
            
            Spacer()
        }
        .frame(width: 232)
        .background(.white)
    }
}

#Preview {
    let sample = SearchViewModel.SearchResult(image: .init(systemName: "plus")!, text: "sample입 fpl fasdjf10 fdsfffffff fvbas -0123rj e입니다", page: 1, count: 10)
    
    SearchListCell(result: sample)
        .frame(width: 300)
}
