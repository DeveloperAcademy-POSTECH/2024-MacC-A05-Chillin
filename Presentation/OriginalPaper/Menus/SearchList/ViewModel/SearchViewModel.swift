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
    @Published public var searchText: String = ""           // TextField 텍스트
    @Published public var searchResults = [SearchResult]()  // 검색 결과 array
    @Published public var isLoading: Bool = false           // 검색 중 알려주는 flag
    @Published public var isSearched: Bool = false          // 검색이 완료되었는지 알려주는 flag
    
    @Published public var searchSelection: PDFSelection?
    @Published public var searchDestination: PDFDestination?
    
    private var searchAnnotations: [PDFAnnotation] = []     // 하이라이팅을 위한 annotation 배열
    private let pdfSharedData: PDFSharedData = .shared
    
    public var isNoMatchTextVisible: Bool {
        !searchText.isEmpty && searchResults.isEmpty && !isLoading && isSearched
    }
    

    /// 검색 결과 구조체
    struct SearchResult: Hashable {
        let text: AttributedString      // 검색 결과가 포함된 텍스트
        let page: Int                   // 키워드가 포함된 페이지 인덱스
        let selection: PDFSelection     // 선택된 selection
    }
}


// MARK: - 데이터 Fetch method
extension SearchViewModel {
    
    /// pdf 검색 메소드
    public func fetchSearchResults(document: PDFDocument) {
        // 백그라운드 쓰레드에서 진행
        // 메인 쓰레드에서 진행 시 검색 중 앱 사용 불가
        DispatchQueue.global().async {
            DispatchQueue.main.async {  // view 업데이트 관련은 메인 쓰레드에서 진행
                self.isLoading = true
            }
            
            guard !self.searchText.isEmpty else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            var results = [SearchResult]()
            
            // 키워드 검색
            let searchSelections = document.findString(self.searchText, withOptions: .caseInsensitive)
            
            var currentPage = -1
            var currentIndex = -1
            
            searchSelections.forEach { selection in
                guard let page = selection.pages.first, let pageText = page.string else { return }
                
                DispatchQueue.main.async {
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
                    
                    results.append(.init(
                        text: resultText,
                        page: pageCount,
                        selection: selection))
                    
                } else {
                    for i in currentIndex ..< textArray.count {
                        if String(textArray[i]).lowercased().contains(selection.string!.lowercased()) {
                            currentIndex = i + 1
                            
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
        
        // 찾으려는 String 배열이 10보다 작을 경우
        if textArray.count < 10 {
            for i in 0 ..< textArray.count {
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
            return resultText
        }
        
        // 찾은 키워드의 인덱스가 5보다 작을 경우
        // 0-10 까지의 string을 들고옴
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
    
    /// 찾은 키워드를 pdfview에 하이라이팅 하는 메소드
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
    
    /// 검색을 종료할 때 하이라이팅을 지우는 메소드
    public func removeAllAnnotations() {
        self.searchAnnotations.forEach { annotation in
            guard let page = annotation.page else { return }
            
            page.removeAnnotation(annotation)
        }
        
        self.searchAnnotations.removeAll()
    }
    
    public func goToPage(at num: Int) {
        guard let page = self.pdfSharedData.document?.page(at: num) else {
            return
        }
        
        let destination = PDFDestination(page: page, at: .zero)
        
        self.searchDestination = destination
    }
}

