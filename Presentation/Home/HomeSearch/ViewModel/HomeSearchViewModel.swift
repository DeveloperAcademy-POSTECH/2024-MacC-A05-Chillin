//
//  HomeSearchViewModel.swift
//  Reazy
//
//  Created by 문인범 on 2/12/25.
//

import Foundation
import SwiftUICore

@MainActor
final class HomeSearchViewModel: ObservableObject, Sendable {
    @Published public var isLoading: Bool = false
    @Published public var searchList: [PaperInfo] = []
    @Published public var searchTarget: SearchTarget = .title
    @Published public var searchText: String = ""
    @Published public var recentSearches: [Tag] = {
        var result = [Tag]()
        UserDefaults.standard.recentSearches.forEach {
            result.append(Tag(name: $0))
        }
        return result
    }()
    @Published public var viewStatus: SearchViewStatus = .normal
    
    private let useCase: HomeSearchUseCase

    private var timer: Timer?
    
    init(useCase: HomeSearchUseCase) {
        self.useCase = useCase
    }
    
    enum SearchViewStatus: Hashable {
        case normal
        case search(PaperInfo)
        case setTag(PaperInfo)
    }
}


extension HomeSearchViewModel {
    public func searchPapers() {
        toggleIsLoading(true)
        if let timer = timer {
            timer.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.loadSearchedList()
            }
        }
    }
    
    public func tagTapped(_ tagId: UUID) {
        
    }
    
    public func starButtonTapped(_ paperInfo: PaperInfo) {
        let id = paperInfo.id
        
        if let paperIndex = searchList.firstIndex(where: { $0.id == id }) {
            searchList[paperIndex].isFavorite.toggle()
            useCase.editPDF(searchList[paperIndex])
        }
    }
    
    public func cellTapped(title: String) {
        self.searchText = title
    }
    
    public func searchTargetButtonTapped(target: SearchTarget) {
        if target == searchTarget { return }
        
        searchTarget = target
        self.searchList.removeAll()
        searchPapers()
    }
    
    public func PaperCellTapped(_ paperInfo: PaperInfo) {
        setRecentSearchList()
        editPaperDate(paperInfo)
    }
    
    public func removeAllButtonTapped() {
        UserDefaults.standard.recentSearches = []
        self.recentSearches.removeAll()
    }
    
    public func deleteButtonTapped(_ paperInfo: PaperInfo) {
        let id = paperInfo.id
        
        useCase.deletePDF(paperInfo)
        if let index = searchList.firstIndex(where: { $0.id == id }) {
            searchList.remove(at: index)
        }
    }
    
    public func copyButtonTapped(_ paperInfo: PaperInfo) {
        let response = useCase.duplicatePDF(paperInfo)
        
        if case .success = response {
            loadSearchedList()
        } else {
            print(#function)
        }
    }
}

// MARK: - EditingTitle 메소드
extension HomeSearchViewModel {
    public func editButtonTapped(_ paperInfo: PaperInfo) {
        withAnimation(.easeInOut) {
            viewStatus = .search(paperInfo)
        }
    }
    
    public func completeButtonTappedInEditingTitle(title: String) {
        if case let .search(paper) = viewStatus,
           let index = searchList.firstIndex(of: paper) {
            searchList[index].title = title
            
            useCase.editPDF(searchList[index])
        }
        
        cancelButtonTappedInEditingTitle()
    }
    
    public func cancelButtonTappedInEditingTitle() {
        withAnimation(.easeInOut) {
            viewStatus = .normal
        }
    }
}

// MARK: - TagControl 메소드
extension HomeSearchViewModel {
    public func setTagButtonTapped(_ paperInfo: PaperInfo) {
        withAnimation(.easeInOut) {
            viewStatus = .setTag(paperInfo)
        }
    }
}


// MARK: - Internal Method
extension HomeSearchViewModel {
    private func loadSearchedList() {
        let response = self.useCase.fetchSearchList(target: self.searchTarget, matches: self.searchText)
        
        switch response {
        case .success(let papers):
           self.fetchSearchList(papers: papers)
        case .failure:
            print(#function)
        }
        self.toggleIsLoading(false)
    }
    
    private func fetchSearchList(papers: [PaperInfo]) {
        self.searchList = papers
    }
    
    private func toggleIsLoading(_ toggle: Bool) {
        self.isLoading = toggle
    }
    
    private func setRecentSearchList() {
        var current = UserDefaults.standard.recentSearches
        
        if current.contains(where: {$0 == self.searchText}) {
            return
        }
        
        if current.count == 30 {
            current.removeFirst()
        }
        
        current.append(self.searchText)
        
        UserDefaults.standard.recentSearches = current
        
        self.recentSearches = current.map {
            Tag(name: $0)
        }
    }
    
    private func editPaperDate(_ paperInfo: PaperInfo) {
        let id = paperInfo.id
        
        if let paperIndex = searchList.firstIndex(where: { $0.id == id }) {
            searchList[paperIndex].lastModifiedDate = .now
            useCase.editPDF(searchList[paperIndex])
        }
    }
}
