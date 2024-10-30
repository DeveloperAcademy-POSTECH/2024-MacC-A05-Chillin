//
//  SearchViewModel.swift
//  Reazy
//
//  Created by 문인범 on 10/29/24.
//

import Foundation
import PDFKit


/**
 검색 결과를 관할하는 ViewModel
 */
final class SearchViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var searchResults = [SearchResult]()
    
    /// 검색 결과 구조체
    struct SearchResult: Hashable {
        let image: UIImage  // 페이지 썸네일
        let text: String    // 검색 결과가 포함된 텍스트
        let page: Int       // 키워드가 포함된 페이지 인덱스
        let count: Int      // 해당 페이지에 키워드가 포함된 갯수
    }
}


// MARK: - 데이터 Fetch method
extension SearchViewModel {
    public func fetchSearchResults(document: PDFDocument) {
        guard !searchText.isEmpty else { return }
        
        var results = [SearchResult]()
        
        // 키워드 검색
        let searchSelections = document.findString(self.searchText)
        
        searchSelections.forEach { selection in
            guard let page = selection.pages.first else { return }
            
            let width = page.bounds(for: .mediaBox).width
            let height = page.bounds(for: .mediaBox).height
            
            // 해당 페이지 썸네일 가져오기
            let thumbnail = page.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            
            // 해당 페이지 인덱스
            let pageCount = document.index(for: page)
            
            // TODO: 해당 키워드가 포함된 텍스트(수정 예정)
            let text = selection.string
            
            results.append(.init(
                image: thumbnail,
                text: text ?? "nothing",
                page: pageCount,
                count: 1))
        }
        
        self.searchResults = results
    }
}

