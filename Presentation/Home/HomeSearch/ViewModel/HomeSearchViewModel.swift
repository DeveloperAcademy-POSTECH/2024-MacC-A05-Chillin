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
    
    private let useCase: HomeSearchUseCase
    
    init(useCase: HomeSearchUseCase) {
        self.useCase = useCase
    }
}


extension HomeSearchViewModel {
    public func fetchSearchList(target: String, matches: String) {
        switch useCase.fetchSearchList(target: target, matches: matches) {
        case .success(let papers):
            self.searchList = papers
        case .failure(let failure):
            print(#function)
        }
    }
}
