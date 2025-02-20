//
//  TagDataRepository.swift
//  Reazy
//
//  Created by 유지수 on 2/9/25.
//

import Foundation

protocol TagDataRepository {
    // 모든 태그 데이터를 가져옵니다
    func fetchAllTags() -> Result<[Tag], Error>
    
    // 해당 태그를 포함하고 있는 모든 문서를 가져옵니다
    func fetchPapersByTag(tagID: UUID) -> Result<[PaperInfo], Error>
    
    // 태그를 추가합니다
    func addTag(name: String) -> Result<Tag, Error>
    
    // 태그를 삭제합니다
    @discardableResult
    func deleteTag(tagID: UUID) -> Result<VoidResponse, Error>
    
    // 태그를 수정합니다
    func renameTag(tagID: UUID, newName: String) -> Result<Tag, Error>
}
