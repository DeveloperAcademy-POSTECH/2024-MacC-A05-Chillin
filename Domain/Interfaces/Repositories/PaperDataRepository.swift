//
//  PaperDataInterface.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation

protocol PaperDataRepository {
    /// 저장된 PDF 정보를 모두 불러옵니다
    func loadPDFInfo() -> Result<[PaperInfo], Error>
    
    
    /// 새로운 PDF를 저장합니다
    @discardableResult
    func savePDFInfo(_ info: PaperInfo) -> Result<VoidResponse, Error>
    
    /// 기존 PDF 정보를 수정합니다
    @discardableResult
    func editPDFInfo(_ info: PaperInfo) -> Result<VoidResponse, Error>
    
    /// PDF 정보를 삭제합니다
    @discardableResult
    func deletePDFInfo(id: UUID) -> Result<VoidResponse, Error>
    
    @discardableResult
    func duplicatePDFInfo(id: UUID, info: PaperInfo) -> Result<VoidResponse, Error>
    
    // 문서에 태그를 추가합니다
    @discardableResult
    func addTag(to id: UUID, with tag: String) -> Result<VoidResponse, Error>
    
    // 문서의 태그를 삭제합니다 : 전체 태그 리스트에서는 유지
    @discardableResult
    func removeTag(from id: UUID, tagID: UUID) -> Result<VoidResponse, Error>
    
    // 문서의 태그를 변경합니다
    @discardableResult
    func replaceTag(for paperId: UUID, oldTagId: UUID, newTagId: UUID) -> Result<VoidResponse, Error>
}
