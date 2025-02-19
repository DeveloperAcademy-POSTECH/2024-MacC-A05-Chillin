//
//  HomeSearchViewModel.swift
//  Reazy
//
//  Created by 문인범 on 2/12/25.
//

import Foundation


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
    
    private let useCase: HomeSearchUseCase

    private var timer: Timer?
    
    init(useCase: HomeSearchUseCase) {
        self.useCase = useCase
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
                let response = await self.useCase.fetchSearchList(target: self.searchTarget, matches: self.searchText)
                
                switch response {
                case .success(let papers):
                    await self.fetchSearchList(papers: papers)
                case .failure:
                    print(#function)
                }
                await self.toggleIsLoading(false)
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
    
    private func fetchSearchList(papers: [PaperInfo]) {
        self.searchList = papers
    }
    
    private func toggleIsLoading(_ toggle: Bool) {
        self.isLoading = toggle
    }
    
    public func cellTapped(title: String) {
        self.searchText = title
    }
    
    public func searchTargetChanged(target: SearchTarget) {
        if target == searchTarget { return }
        
        searchTarget = target
        self.searchList.removeAll()
        searchPapers()
    }
    
    public func removeAllRecentSearches() {
        UserDefaults.standard.recentSearches = []
        self.recentSearches.removeAll()
    }
    
    public func setRecentSearchList() {
        var current = UserDefaults.standard.recentSearches
        
        if current.count == 30 {
            current.removeFirst()
        }
        
        current.append(self.searchText)
        
        UserDefaults.standard.recentSearches = current
        
        self.recentSearches = current.map {
            Tag(name: $0)
        }
        
    }
}
