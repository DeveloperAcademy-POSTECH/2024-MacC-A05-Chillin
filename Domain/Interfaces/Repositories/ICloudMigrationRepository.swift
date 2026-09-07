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

    /// 논문의 파일 위치(북마크 + 저장소 기준 상대 경로)를 새 위치로 갱신합니다
    @discardableResult
    func updateFileLocation(
        id: UUID,
        url: Data,
        relativePath: String?,
        focusURL: Data?,
        focusRelativePath: String?
    ) -> Result<VoidResponse, Error>

    /// 썸네일이 지정한 크기보다 큰 논문의 id를 찾습니다
    func fetchPaperIDsWithLargeThumbnail(largerThan threshold: Int) -> Result<[UUID], Error>

    /// 썸네일만 교체합니다. 파일 경로 관련 필드는 건드리지 않습니다
    @discardableResult
    func updateThumbnail(id: UUID, thumbnail: Data) -> Result<VoidResponse, Error>

    /// 상대 경로만 채워 넣습니다. 북마크(url/focusURL)는 절대 건드리지 않으므로
    /// 백필이 잘못되더라도 기존 경로로 논문을 여는 데는 아무 영향이 없습니다
    @discardableResult
    func updateRelativePaths(id: UUID, relativePath: String?, focusRelativePath: String?) -> Result<VoidResponse, Error>
}
