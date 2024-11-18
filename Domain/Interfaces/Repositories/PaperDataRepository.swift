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
}
