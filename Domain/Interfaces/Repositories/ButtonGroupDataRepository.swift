//
//  ButtonGroupDataInterface.swift
//  Reazy
//
//  Created by 유지수 on 11/11/24.
//

import Foundation

protocol ButtonGroupDataRepository {
    /// 저장된 버튼 그룹을 불러옵니다
    func loadButtonGroup(for pdfID: UUID) -> Result<[ButtonGroup], Error>
    
    /// 버튼 그룹을 저장합니다
    @discardableResult
    func saveButtonGroup(for pdfID: UUID, with buttonGroup: ButtonGroup) -> Result<VoidResponse, Error>
    
    /// 버튼 그룹을 삭제합니다
    @discardableResult
    func deleteButtonGroup(for pdfID: UUID, id: UUID) -> Result<VoidResponse, Error>
}
