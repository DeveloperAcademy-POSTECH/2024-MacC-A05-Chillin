//
//  HomeSearchUseCase.swift
//  Reazy
//
//  Created by 문인범 on 2/13/25.
//

import Foundation


protocol HomeSearchUseCase: Sendable {
    func fetchSearchList(target: SearchTarget, matches: String) -> Result<[PaperInfo], any Error>
    func fetchByTagId(tagId: UUID) -> Result<[PaperInfo], any Error>
    
    @discardableResult
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
}

enum SearchTarget {
    case title
    case tag
}

final class DefaultHomeSearchUseCase: HomeSearchUseCase {
    private let paperDataRepository: PaperDataRepository
    private let tagDataRepository: TagDataRepository
    
    init(paperDataRepository: PaperDataRepository, tagDataRepository: TagDataRepository) {
        self.paperDataRepository = paperDataRepository
        self.tagDataRepository = tagDataRepository
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
            let papers = fetchPapersByTagName(matches)
            return .success(papers)
        }
    }
    
    func fetchByTagId(tagId: UUID) -> Result<[PaperInfo], any Error> {
        let response = tagDataRepository.fetchPapersByTag(tagID: tagId)
        if case let .success(papers) = response {
            return .success(papers)
        }
        return .failure(NSError())
    }
    
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.editPDFInfo(info)
    }
    
    private func fetchPapersByTagName(_ tagName: String) -> [PaperInfo] {
        let response = tagDataRepository.fetchAllTags()
        if case let .success(tags) = response {
            let result = tags.filter { $0.name == tagName }
            
            if result.isEmpty {
                return []
            }
            
            let paperTagResponse = tagDataRepository.fetchPapersByTag(tagID: result.first!.id)
            guard case let .success(papers) = paperTagResponse else { return [] }
            
            return papers
        }
        return []
    }
}


