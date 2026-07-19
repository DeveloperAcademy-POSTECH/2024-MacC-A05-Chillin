//
//  ICloudMigrationRepository.swift
//  Reazy
//
//  Created by Claude on 7/19/26.
//

import Foundation

protocol ICloudMigrationRepository: Sendable {
    /// 마이그레이션 대상이 되는 모든 논문의 파일 위치(북마크)를 불러옵니다
    func fetchAllPaperLocations() -> Result<[PaperFileLocation], Error>

    /// 특정 논문 하나의 파일 위치(북마크)를 다시 불러옵니다 (재개 시 최신 상태 확인용)
    func fetchPaperLocation(id: UUID) -> Result<PaperFileLocation, Error>

    /// 논문의 파일 위치(북마크)를 새 위치로 갱신합니다
    @discardableResult
    func updateFileLocation(id: UUID, url: Data, focusURL: Data?) -> Result<VoidResponse, Error>
}
