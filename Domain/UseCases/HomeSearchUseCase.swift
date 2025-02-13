//
//  HomeSearchUseCase.swift
//  Reazy
//
//  Created by 문인범 on 2/13/25.
//

import Foundation


protocol HomeSearchUseCase {
    func fetchSearchList(target: SearchTarget, matches: String) -> Result<[PaperInfo], any Error>
}

enum SearchTarget {
    case title
    case tag
}

final class DefaultHomeSearchUseCase: HomeSearchUseCase {
    private let paperDataRepository: PaperDataRepository
    
    init(paperDataRepository: PaperDataRepository) {
        self.paperDataRepository = paperDataRepository
    }
    
    func fetchSearchList(target: SearchTarget, matches: String) -> Result<[PaperInfo], any Error> {
        switch target {
        case .title:
            let response = paperDataRepository.loadPDFInfo()
            if case let .success(papers) = response {
                let result = papers.filter { $0.title.localizedStandardContains(matches) }
                return .success(result)
            } else {
                return .failure(NSError())
            }
        case .tag:
            // TODO: 태그 검색 기능 구현
            return .failure(NSError())
        }
    }
}


