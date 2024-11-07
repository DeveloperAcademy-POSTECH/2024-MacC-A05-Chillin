//
//  DrawingDataInterface.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation

protocol DrawingDataInterface {
    /// 필기 기록을 불러옵니다
    func loadDrawingData(for pdfID: UUID) -> Result<[Drawing], Error>
    /// 필기 기록을 저장합니다
    func saveDrawingData(for pdfID: UUID, with drawing: Drawing) -> Result<VoidResponse, Error>
    /// 필기 기록을 삭제합니다
    func deleteDrawingData(for pdfID: UUID, id: UUID) -> Result<VoidResponse, Error>
}
