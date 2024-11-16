//
//  FigureDataInterface.swift
//  Reazy
//
//  Created by 유지수 on 11/10/24.
//

import Foundation

protocol FigureDataInterface {
    /// 저장된 FigureData를 불러옵니다
    func loadFigureData(for pdfID: UUID) -> Result<[Figure], Error>
    /// FigureData를 저장합니다
    func saveFigureData(for pdfID: UUID, with figure: Figure) -> Result<VoidResponse, Error>
    /// FigureData를 수정합니다
    func editFigureData(for pdfID: UUID, with figure: Figure) -> Result<VoidResponse, Error>
    /// FigureData를 삭제합니다
    func deleteFigureData(for pdfID: UUID, id: String) -> Result<VoidResponse, Error>
    
    func editPaperInfo(info: PaperInfo) -> Result<VoidResponse, any Error>
}
