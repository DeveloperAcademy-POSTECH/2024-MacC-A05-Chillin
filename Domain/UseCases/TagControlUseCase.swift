//
//  TagControlUseCase.swift
//  Reazy
//
//  Created by 문인범 on 3/6/25.
//

import Foundation



protocol TagControlUseCase {
    @discardableResult
    func addTagToPaper(to paperId: UUID, with tag: String) -> Result<VoidResponse, Error>
    
    @discardableResult
    func removeTagFromPaper(to paperId: UUID, with tagId: UUID) -> Result<VoidResponse, Error>
    
    @discardableResult
    func createTag(_ name: String) -> Result<Tag, Error>
    
    func searchTags(_ name: String) throws -> [Tag]
}


final class DefaultTagControlUseCase: TagControlUseCase {
    private let paperDataRepository: PaperDataRepository
    private let tagRepository: TagDataRepository
    
    init(paperDataRepository: PaperDataRepository, tagRepository: TagDataRepository) {
        self.paperDataRepository = paperDataRepository
        self.tagRepository = tagRepository
    }
    
    func addTagToPaper(to paperId: UUID, with tag: String) -> Result<VoidResponse, Error> {
        paperDataRepository.addTag(to: paperId, with: tag)
    }
    
    func removeTagFromPaper(to paperId: UUID, with tagId: UUID) -> Result<VoidResponse, Error> {
        paperDataRepository.removeTag(from: paperId, tagID: tagId)
    }
    
    func createTag(_ name: String) -> Result<Tag, Error> {
        tagRepository.addTag(name: name)
    }
    
    func searchTags(_ name: String) throws -> [Tag] {
        let tags = tagRepository.fetchAllTags()
        
        switch tags {
        case let .success(tags):
            let filteredResult = tags.filter { $0.name.localizedCaseInsensitiveContains(name) }
            return filteredResult
        case .failure:
            throw NSError()
        }
    }
}
