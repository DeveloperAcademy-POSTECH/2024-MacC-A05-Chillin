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
        guard !searchText.isEmpty else {
            return
        }
        
        var results = [SearchResult]()
        
        // 키워드 검색
        let searchSelections = document.findString(self.searchText)
        
        var currentPage = -1
        var currentIndex = -1
        
        searchSelections.forEach { selection in
            guard let page = selection.pages.first, let pageText = page.string else { return }
            
            // 해당 페이지 인덱스
            let pageCount = document.index(for: page)
            
            if currentPage != pageCount {
                currentPage = pageCount
                currentIndex = -1
            }
            
            let width = page.bounds(for: .mediaBox).width
            let height = page.bounds(for: .mediaBox).height
            
            // 해당 페이지 썸네일 가져오기
            let thumbnail = page.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            
            let textArray = pageText.split(separator: " ")
            
            if currentIndex == -1 {
                let index = textArray.firstIndex { String($0).lowercased().contains(selection.string!.lowercased()) }!
                
                let resultText = self.fetchKeywordContainedString(index: index, textArray: textArray)
                
                currentIndex = index + 1
                
                print(resultText)
            } else {
                for i in currentIndex ..< textArray.count {
                    if String(textArray[i]).lowercased().contains(selection.string!.lowercased()) {
                        currentIndex = i + 1
                        
                        print(self.fetchKeywordContainedString(index: i, textArray: textArray))
                        
                        results.append(.init(
                            image: thumbnail,
                            text: self.fetchKeywordContainedString(index: i, textArray: textArray),
                            page: pageCount,
                            count: 1))
                        break
                    }
                }
            }
            
            // TODO: 해당 키워드가 포함된 텍스트(수정 예정)
        }
        
        self.searchResults = results
    }
    
    /// 해당 키워드가 포함된 문장 앞 뒤로 짤라서 가져오는 메소드
    private func fetchKeywordContainedString(index: Int, textArray: [String.SubSequence]) -> String {
        var resultText = ""
        
        if index < 4 {
            for i in 0 ..< 10 {
                let text = textArray[i].replacingOccurrences(of: "\n", with: " ")
                resultText.append(text + " ")
            }
        } else if index > textArray.count - 5 {
            for i in textArray.count - 10 ..< textArray.count {
                let text = textArray[i].replacingOccurrences(of: "\n", with: " ")
                resultText.append(text + " ")
            }
        } else {
            for i in index - 5 ..< index + 5 {
                let text = textArray[i].replacingOccurrences(of: "\n", with: " ")
                resultText.append(text + " ")
            }
        }
        
        return resultText
    }
}

