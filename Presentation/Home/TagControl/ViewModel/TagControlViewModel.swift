//
//  TagControlViewModel.swift
//  Reazy
//
//  Created by 문인범 on 3/7/25.
//

import Foundation


/**
 태그 관리 뷰 모델
 */
@MainActor
final class TagControlViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var searchedTags = [Tag]()
    @Published public var isLoading = false
    @Published public var isOverMaximumTagAlertPresented: Bool = false
    
    public var recentAddedTags: [Tag] {
        fetchRecentAddedTags()
    }
    private var timer: Timer?
    
    
    private let useCase: TagControlUseCase
    init(useCase: TagControlUseCase) {
        self.useCase = useCase
    }
    
}



extension TagControlViewModel {
    public func searchTagButtonTapped() {
        guard !searchText.isEmpty else { return }
        self.isLoading = true
        
        if let timer = timer {
            timer.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.loadSearchedTags()
            }
        }
    }
    
    public func onSubmit(paperInfo: PaperInfo) -> Tag? {
        guard !searchText.isEmpty || isLoading else { return nil }
        defer { searchText.removeAll() }
        
        // TODO: 에러 처리(alert 창 연결)
        if paperInfo.tags.count >= 7 {
            isOverMaximumTagAlertPresented = true
            return nil
        }
        
        if let firstTag = searchedTags.first, paperInfo.tags.contains(where: { $0 == firstTag }) {
            // TODO: 에러 처리(alert 창 연결)
            return nil
        }
        if searchedTags.isEmpty {
            createNewTagButtonTapped()
        }
        
        if let tag = addTagToPDF(pdfId: paperInfo.id, tagName: searchText) {
            addRecentSearchedTag(tag)
            return tag
        }
        // TODO: 에러 처리(alert 창 연결)
        return nil
    }
    
    public func existingTagTapped(paperInfo: PaperInfo, tag: Tag) -> Tag? {
        defer { searchText.removeAll() }
        // TODO: 에러 처리(alert 창 연결)
        if paperInfo.tags.count >= 7 {
            isOverMaximumTagAlertPresented = true
            return nil
        }
        if paperInfo.tags.contains(tag) { return nil }
        
        if let tag = addTagToPDF(pdfId: paperInfo.id, tagName: tag.name) {
            addRecentSearchedTag(tag)
            return tag
        }
        return nil
    }
    
    public func createNewTagButtonTapped() {
        guard !searchText.isEmpty else { return }
        
        self.useCase.createTag(searchText)
    }
    
    public func deleteTagButtonTapped(paperId: UUID, tag: Tag) {
        self.useCase.removeTagFromPaper(to: paperId, with: tag.id)
    }
}


// MARK: - Internal method
extension TagControlViewModel {
    /// 최근 태그 검색 기록 불러오기
    private func fetchRecentAddedTags() -> [Tag] {
        let response = UserDefaults.standard.lastSearchTags
        var result = [Tag]()
        
        response.forEach {
            result.append(Tag(id: UUID(uuidString: $1)!, name: $0))
        }
        return result
    }
    
    /// 태그 검색 결과
    private func loadSearchedTags() {
        defer { self.isLoading = false }
        
        do {
            let response = try self.useCase.searchTags(searchText)
            searchedTags = response
        } catch {
            
        }
    }
    
    /// Paperinfo에 태그 추가
    private func addTagToPDF(pdfId: UUID, tagName: String) -> Tag? {
        // TODO: 에러 처리(alert 창 연결)
        try? useCase.addTagToPaper(to: pdfId, with: tagName).get()
    }
    
    /// 최근 검색 기록 추가
    private func addRecentSearchedTag(_ tag: Tag) {
        var response = UserDefaults.standard.lastSearchTags
        if !response.values.contains(where: { UUID(uuidString: $0)! == tag.id }) {
            response[tag.name] = tag.id.uuidString
            UserDefaults.standard.lastSearchTags = response
        }
    }
}



// MARK: - View Flags
extension TagControlViewModel {
    public var showingSearchPlaceholder: Bool {
        !isLoading && searchedTags.isEmpty && searchText.isEmpty && recentAddedTags.isEmpty
    }
    
    public var showingRecentAddedTags: Bool {
        !isLoading && searchedTags.isEmpty && searchText.isEmpty && !recentAddedTags.isEmpty
    }
    
    public var showingCreateNewTag: Bool {
        !isLoading && searchedTags.isEmpty && !searchText.isEmpty
    }
    
    public var showingExistingTags: Bool {
        !isLoading && !searchedTags.isEmpty
    }
}
