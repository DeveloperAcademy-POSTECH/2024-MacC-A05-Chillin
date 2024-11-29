//
//  CollectionDataRepository.swift
//  Reazy
//
//  Created by 유지수 on 11/27/24.
//

import Foundation

protocol CollectionDataRepository {
    /// 저장된 모아보기 데이터를 불러옵니다
    func loadCollectionData(for pdfID: UUID) -> Result<[Figure], Error>
    
    /// 모아보기 데이터를 저장합니다
    @discardableResult
    func saveCollectionData(for pdfID: UUID, with collection: Figure) -> Result<VoidResponse, Error>
    
    /// 모아보기 데이터를 수정합니다
    @discardableResult
    func editFigureData(for pdfID: UUID, with collection: Figure) -> Result<VoidResponse, Error>
    
    /// 모아보기 데이터를 삭제합니다
    @discardableResult
    func deleteCollectionData(for pdfID: UUID, id: String) -> Result<VoidResponse, Error>
}
