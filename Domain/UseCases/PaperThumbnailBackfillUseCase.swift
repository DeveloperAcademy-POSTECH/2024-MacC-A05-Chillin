//
//  PaperThumbnailBackfillUseCase.swift
//  Reazy
//
//  Created by Claude on 9/7/26.
//

import Foundation
import UIKit
import PDFKit

/// 논문 썸네일을 만드는 규칙. 업로드 시점과 백필이 같은 결과를 내도록 한 곳에 모아 둔다
enum PaperThumbnailMaker {
    /// 홈 목록 셀에 82x110pt로 표시되므로 페이지 원본 크기 그대로 저장할 필요가 없다.
    /// CloudKit은 레코드 하나당 약 1MB 제한이 있어서, 큰 판형이거나 그림이 많은 페이지를
    /// 무압축 PNG로 넣으면 그 논문만 조용히 동기화에 실패한다
    static let maxLength: CGFloat = 600

    static func makeData(from page: PDFPage) -> Data? {
        let pageSize = page.bounds(for: .mediaBox).size
        guard pageSize.width > 0, pageSize.height > 0 else { return nil }

        let scale = min(1, maxLength / max(pageSize.width, pageSize.height))
        let targetSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)

        return page.thumbnail(of: targetSize, for: .mediaBox).jpegData(compressionQuality: 0.8)
    }
}

protocol PaperThumbnailBackfillUseCase {
    /// 예전 규칙으로 만들어져 지나치게 큰 썸네일을 다시 만들어 저장합니다
    func backfill() async
}

/**
 예전 버전에서 만들어진 큰 썸네일을 다시 만든다.

 썸네일 크기 제한(600pt + JPEG)은 새로 추가되는 논문에만 적용되고,
 모델의 External Storage 설정은 Core Data가 값을 *새로 쓸 때*만 판정하므로
 lightweight migration으로 이월된 기존 썸네일은 둘 다에 해당되지 않는다.
 1MB를 넘는 것이 남아 있으면 그 논문만 CloudKit 동기화에 계속 실패한다.

 여기서 다시 만들어 저장하면 크기가 줄어들고, 새로 쓰이면서 저장 방식도 다시 판정받는다.

 - 임계값을 넘는 논문만 처리한다. 전부 다시 만들면 실행할 때마다 모든 PDF를 여는 셈이라 느리다.
 - 파일을 읽을 수 없으면(아직 내려받지 않은 iCloud 파일 등) 건너뛴다. 다음 실행에서 다시 시도한다.
 - 실패해도 기존 썸네일은 그대로 남으므로 목록이 비어 보이는 일은 없다.
 */
final class DefaultPaperThumbnailBackfillUseCase: PaperThumbnailBackfillUseCase {
    /// 이 크기를 넘는 썸네일만 다시 만든다. CloudKit 레코드 한도(약 1MB)에 여유를 두고 잡았다
    private static let sizeThreshold = 300 * 1024

    private let migrationRepository: ICloudMigrationRepository

    init(migrationRepository: ICloudMigrationRepository) {
        self.migrationRepository = migrationRepository
    }

    func backfill() async {
        let targets: [UUID]

        switch migrationRepository.fetchPaperIDsWithLargeThumbnail(largerThan: Self.sizeThreshold) {
        case .success(let value):
            targets = value
        case .failure(let error):
            log("썸네일 백필: 대상을 찾지 못했습니다 - \(error)")
            return
        }

        guard !targets.isEmpty else { return }

        var rebuilt = 0
        var skipped = 0

        for id in targets {
            guard case .success(let location) = migrationRepository.fetchPaperLocation(id: id) else {
                skipped += 1
                continue
            }

            guard let url = PaperFileLocator.resolve(
                relativePath: location.relativePath,
                bookmark: location.url,
                title: location.title
            )?.url else {
                skipped += 1
                continue
            }

            // 아직 내려받지 않은 iCloud 파일이면 document가 nil이 된다 — 다음 기회로 미룬다
            guard let page = PDFDocument(url: url)?.page(at: 0),
                  let thumbnail = PaperThumbnailMaker.makeData(from: page) else {
                skipped += 1
                continue
            }

            if case .failure(let error) = migrationRepository.updateThumbnail(id: id, thumbnail: thumbnail) {
                log("썸네일 백필 실패 (\(location.title)): \(error)")
                skipped += 1
                continue
            }

            rebuilt += 1
        }

        log("썸네일 백필: \(rebuilt)건 재생성, \(skipped)건 보류")
    }
}
