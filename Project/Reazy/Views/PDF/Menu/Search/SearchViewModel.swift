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
    @Published public var isLoading: Bool = false
    @Published public var isSearched: Bool = false
    
    private var searchAnnotations: [PDFAnnotation] = []
    
    public var isNoMatchTextVisible: Bool {
        !searchText.isEmpty && searchResults.isEmpty && !isLoading && isSearched
    }
    
    /// 검색 결과 구조체
    struct SearchResult: Hashable {
        let text: AttributedString    // 검색 결과가 포함된 텍스트
        let page: Int       // 키워드가 포함된 페이지 인덱스
        let selection: PDFSelection
    }
}


// MARK: - 데이터 Fetch method
extension SearchViewModel {
    public func fetchSearchResults(document: PDFDocument) {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.isLoading = true
            }
            
            guard !self.searchText.isEmpty else {
                return
            }
            
            var results = [SearchResult]()
            
            // 키워드 검색
            let searchSelections = document.findString(self.searchText)
            
            var currentPage = -1
            var currentIndex = -1
            
            searchSelections.forEach { selection in
                guard let page = selection.pages.first, let pageText = page.string else { return }
                
                DispatchQueue.main.async{
                    self.addAnnotations(document: document, selection: selection)
                }
                
                // 해당 페이지 인덱스
                let pageCount = document.index(for: page)
                
                if currentPage != pageCount {
                    currentPage = pageCount
                    currentIndex = -1
                }
                
                let textArray = pageText.split { $0 == " " || $0 == "\n"}
                
                let keyword = selection.string!.lowercased()
                
                if currentIndex == -1 {
                    let index = textArray.firstIndex { String($0).lowercased().contains(keyword) }!
                    
                    let resultText = self.fetchKeywordContainedString(index: index, textArray: textArray, keyword: keyword)
                    
                    currentIndex = index + 1
                    
                    print(resultText)
                    
                    results.append(.init(
                        text: resultText,
                        page: pageCount,
                        selection: selection))
                    
                } else {
                    for i in currentIndex ..< textArray.count {
                        if String(textArray[i]).lowercased().contains(selection.string!.lowercased()) {
                            currentIndex = i + 1
                            
                            print(self.fetchKeywordContainedString(index: i, textArray: textArray, keyword: keyword))
                            
                            results.append(.init(
                                text: self.fetchKeywordContainedString(index: i, textArray: textArray, keyword: keyword),
                                page: pageCount,
                                selection: selection))
                            break
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.searchResults = results
                self.isLoading = false
                self.isSearched = true
            }
        }
    }
    
    /// 해당 키워드가 포함된 문장 앞 뒤로 짤라서 가져오는 메소드
    private func fetchKeywordContainedString(index: Int, textArray: [String.SubSequence], keyword: String) -> AttributedString {
        
        var resultText: AttributedString = .init()
        // TODO: 필요 시 행간 조절 필요
//        let paragraphStyle: NSMutableParagraphStyle = .init()
//        paragraphStyle.lineSpacing = -10
        
        if index < 5 {
            for i in 0 ..< 10 {
                let text = textArray[i].replacingOccurrences(of: "\n", with: " ")
                if i == index {
                    var attributedText = AttributedString(text)
                    
                    let attributes: AttributeContainer = .init([
                        .foregroundColor: UIColor.gray800,
                        .font: UIFont.init(name: ReazyFontType.pretendardRegularFont, size: 12)!,
                    ])
                    
                    attributedText.setAttributes(attributes)
                    
                    let range = attributedText.range(of: keyword, options: .caseInsensitive)
                    attributedText[range!].font = .custom(ReazyFontType.pretendardBoldFont, size: 12)
                    
                    resultText.append(attributedText + " ")
                    continue
                }
                
                var attributedText = AttributedString(text)
                
                let attributes: AttributeContainer = .init([
                    .foregroundColor: UIColor.gray800,
                    .font: UIFont.init(name: ReazyFontType.pretendardRegularFont, size: 12)!,
                ])
                
                attributedText.setAttributes(attributes)
                
                resultText.append(attributedText + " ")
            }
        } else if index > textArray.count - 5 {
            for i in textArray.count - 10 ..< textArray.count {
                let text = textArray[i].replacingOccurrences(of: "\n", with: " ")
                
                if i == index {
                    var attributedText = AttributedString(text)
                    
                    let attributes: AttributeContainer = .init([
                        .foregroundColor: UIColor.gray800,
                        .font: UIFont.init(name: ReazyFontType.pretendardRegularFont, size: 12)!,
                    ])
                    
                    attributedText.setAttributes(attributes)
                    
                    let range = attributedText.range(of: keyword, options: .caseInsensitive)
                    attributedText[range!].font = .custom(ReazyFontType.pretendardBoldFont, size: 12)
                    
                    resultText.append(attributedText + " ")
                    continue
                }
                
                var attributedText = AttributedString(text)
                
                let attributes: AttributeContainer = .init([
                    .foregroundColor: UIColor.gray800,
                    .font: UIFont.init(name: ReazyFontType.pretendardRegularFont, size: 12)!,
                ])
                
                attributedText.setAttributes(attributes)
                
                resultText.append(attributedText + " ")
            }
        } else {
            for i in index - 5 ..< index + 5 {
                let text = textArray[i].replacingOccurrences(of: "\n", with: " ")
                
                if i == index {
                    var attributedText = AttributedString(text)
                    
                    let attributes: AttributeContainer = .init([
                        .foregroundColor: UIColor.gray800,
                        .font: UIFont.init(name: ReazyFontType.pretendardRegularFont, size: 12)!,
                    ])
                    
                    attributedText.setAttributes(attributes)
                    
                    let range = attributedText.range(of: keyword, options: .caseInsensitive)
                    attributedText[range!].font = .custom(ReazyFontType.pretendardBoldFont, size: 12)
                    
                    resultText.append(attributedText + " ")
                    continue
                }
                
                var attributedText = AttributedString(text)
                
                let attributes: AttributeContainer = .init([
                    .foregroundColor: UIColor.gray800,
                    .font: UIFont.init(name: ReazyFontType.pretendardRegularFont, size: 12)!,
                ])
                
                attributedText.setAttributes(attributes)
                
                resultText.append(attributedText + " ")
            }
        }
        
        return resultText
    }
    
    
    private func addAnnotations(document: PDFDocument, selection: PDFSelection) {
        guard let page = selection.pages.first else { return }
        
        selection.selectionsByLine().forEach { select in
            let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
            highlight.endLineStyle = .square
            highlight.color = .init(hex: "FED366").withAlphaComponent(0.5)
            
            self.searchAnnotations.append(highlight)
            page.addAnnotation(highlight)
        }
    }
    
    public func removeAllAnnotations() {
        self.searchAnnotations.forEach { annotation in
            guard let page = annotation.page else { return }
            
            page.removeAnnotation(annotation)
        }
        
        self.searchAnnotations.removeAll()
    }
}

