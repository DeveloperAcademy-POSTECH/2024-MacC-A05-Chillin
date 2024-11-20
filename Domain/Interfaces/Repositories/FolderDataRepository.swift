//
//  FolderDataRepository.swift
//  Reazy
//
//  Created by 유지수 on 11/19/24.
//

import Foundation

protocol FolderDataRepository {
    /// 저장된 폴더 정보를 모두 불러옵니다
    func loadFolders() -> Result<[Folder], Error>
    
    
    /// 새로운 폴더를 생성합니다
    @discardableResult
    func saveFolder(_ folder: Folder) -> Result<VoidResponse, Error>
    
    /// 기존 폴더 정보를 수정합니다
    @discardableResult
    func editFolder(_ folder: Folder) -> Result<VoidResponse, Error>
    
    /// 폴더를 삭제합니다
    @discardableResult
    func deleteFolder(id: UUID) -> Result<VoidResponse, Error>
}
