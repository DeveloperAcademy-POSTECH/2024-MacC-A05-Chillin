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
    
    private var searchAnnotations: [PDFAnnotation] = []
    
    /// 검색 결과 구조체
    struct SearchResult: Hashable {
        let image: UIImage  // 페이지 썸네일
        let text: AttributedString    // 검색 결과가 포함된 텍스트
        let page: Int       // 키워드가 포함된 페이지 인덱스
        let count: Int      // 해당 페이지에 키워드가 포함된 갯수
        let selection: PDFSelection
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
            
            self.addAnnotations(document: document, selection: selection)
            
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
            
            let textArray = pageText.split { $0 == " " || $0 == "\n"}

            let keyword = selection.string!.lowercased()

            if currentIndex == -1 {
                let index = textArray.firstIndex { String($0).lowercased().contains(keyword) }!
                
                let resultText = self.fetchKeywordContainedString(index: index, textArray: textArray, keyword: keyword)
                
                currentIndex = index + 1
                
                print(resultText)
                
                results.append(.init(
                    image: thumbnail,
                    text: resultText,
                    page: pageCount,
                    count: 1,
                    selection: selection))
                
            } else {
                for i in currentIndex ..< textArray.count {
                    if String(textArray[i]).lowercased().contains(selection.string!.lowercased()) {
                        currentIndex = i + 1
                        
                        print(self.fetchKeywordContainedString(index: i, textArray: textArray, keyword: keyword))
                        
                        results.append(.init(
                            image: thumbnail,
                            text: self.fetchKeywordContainedString(index: i, textArray: textArray, keyword: keyword),
                            page: pageCount,
                            count: 1,
                            selection: selection))
                        break
                    }
                }
            }
            
            // TODO: 해당 키워드가 포함된 텍스트(수정 예정)
        }
        
        self.searchResults = results
    }
    
    /// 해당 키워드가 포함된 문장 앞 뒤로 짤라서 가져오는 메소드
    private func fetchKeywordContainedString(index: Int, textArray: [String.SubSequence], keyword: String) -> AttributedString {
        var resultText: AttributedString = .init()
        // TODO: 필요 시 행간 조절 필요
//        let paragraphStyle: NSMutableParagraphStyle = .init()
//        paragraphStyle.lineSpacing = -10
        
        if index < 4 {
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
            highlight.color = .init(hex: "FED366")
            
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

