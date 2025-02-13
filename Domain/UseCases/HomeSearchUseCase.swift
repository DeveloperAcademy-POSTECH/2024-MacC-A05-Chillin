//
//  HomeSearchUseCase.swift
//  Reazy
//
//  Created by 문인범 on 2/13/25.
//

import Foundation


protocol HomeSearchUseCase {
    func fetchSearchList(target: String, matches: String) -> Result<[PaperInfo], any Error>
}


final class DefaultHomeSearchUseCase: HomeSearchUseCase {
    private let paperDataRepository: PaperDataRepository
    
    init(paperDataRepository: PaperDataRepository) {
        self.paperDataRepository = paperDataRepository
    }
    
    func fetchSearchList(target: String, matches: String) -> Result<[PaperInfo], any Error> {
        if target == "title" {
            let response = paperDataRepository.loadPDFInfo()
            if case let .success(papers) = response {
                let result = papers.filter { $0.title.localizedStandardContains(matches) }
                return .success(result)
            } else {
                return .failure(NSError())
            }
        }
        
        return .failure(NSError())
    }
    
    
}
