//
//  HomeSearchViewModel.swift
//  Reazy
//
//  Created by 문인범 on 2/12/25.
//

import Foundation


@MainActor
final class HomeSearchViewModel: ObservableObject {
    @Published public var searchList: [PaperInfo] = []
    @Published public var searchTarget: SearchTarget = .title
    @Published public var searchText: String = ""
    
    private let useCase: HomeSearchUseCase
    
    init(useCase: HomeSearchUseCase) {
        self.useCase = useCase
    }
}


extension HomeSearchViewModel {
    public func fetchSearchList() {
        setRecentSearchList()
        
        switch useCase.fetchSearchList(target: self.searchTarget, matches: searchText) {
        case .success(let papers):
            self.searchList = papers
        case .failure:
            print(#function)
        }
    }
    
    public func searchTargetChanged(target: SearchTarget) {
        if target == searchTarget { return }
        
        searchTarget = target
        self.searchList.removeAll()
        fetchSearchList()
    }
    
    private func setRecentSearchList() {
        var current = UserDefaults.standard.recentSearches
        
        if current.count == 30 {
            current.removeFirst()
        }
        
        current.append(self.searchText)
    }
}
