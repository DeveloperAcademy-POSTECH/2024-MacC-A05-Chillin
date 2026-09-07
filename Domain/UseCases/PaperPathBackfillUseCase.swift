//
//  PaperPathBackfillUseCase.swift
//  Reazy
//
//  Created by Claude on 9/7/26.
//

import Foundation

protocol PaperPathBackfillUseCase {
    /// 상대 경로가 아직 비어 있는 논문을 찾아 현재 위치를 기록합니다
    func backfill() async
}

/**
 기존 사용자의 논문에 저장소 기준 상대 경로를 채워 넣는다.

 이 작업은 **파일을 전혀 건드리지 않는다.** 북마크를 풀어 위치를 계산하고 그 결과를
 CoreData의 relativePath에만 기록한다. 북마크(url/focusURL)도 손대지 않으므로,
 중간에 실패하거나 값이 잘못 들어가도 `PaperFileLocator`의 2·3단계 폴백이 그대로 살아 있어
 논문이 열리지 않게 되는 일은 없다.

 멱등하므로 매 실행마다 호출해도 이미 채워진 논문은 건너뛴다.
 */
final class DefaultPaperPathBackfillUseCase: PaperPathBackfillUseCase {
    private let migrationRepository: ICloudMigrationRepository

    init(migrationRepository: ICloudMigrationRepository) {
        self.migrationRepository = migrationRepository
    }

    func backfill() async {
        let locations: [PaperFileLocation]

        switch migrationRepository.fetchAllPaperLocations() {
        case .success(let value):
            locations = value
        case .failure(let error):
            log("상대 경로 백필: 논문 목록을 불러오지 못했습니다 - \(error)")
            return
        }

        var filled = 0

        for location in locations {
            let needsPath = location.relativePath == nil
            let needsFocusPath = location.focusRelativePath == nil && location.focusURL != nil

            guard needsPath || needsFocusPath else { continue }

            var newRelativePath = location.relativePath
            var newFocusRelativePath = location.focusRelativePath

            if needsPath {
                // relativePath에 nil을 넘겨 1단계를 건너뛰고 북마크/제목으로만 위치를 찾는다
                newRelativePath = PaperFileLocator.resolve(
                    relativePath: nil,
                    bookmark: location.url,
                    title: location.title
                )?.repairedRelativePath
            }

            if needsFocusPath {
                newFocusRelativePath = PaperFileLocator.resolve(
                    relativePath: nil,
                    bookmark: location.focusURL,
                    title: nil
                )?.repairedRelativePath
            }

            // 찾지 못한 논문은 그대로 둔다. 다음 실행에서 다시 시도하고,
            // 그 사이에도 북마크 폴백으로 정상 동작한다
            guard newRelativePath != location.relativePath
                    || newFocusRelativePath != location.focusRelativePath else { continue }

            if case .failure(let error) = migrationRepository.updateRelativePaths(
                id: location.id,
                relativePath: newRelativePath,
                focusRelativePath: newFocusRelativePath
            ) {
                log("상대 경로 백필 실패 (\(location.title)): \(error)")
                continue
            }

            filled += 1
        }

        if filled > 0 {
            log("상대 경로 백필 완료: \(filled)건")
        }
    }
}
