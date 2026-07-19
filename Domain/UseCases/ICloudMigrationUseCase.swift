//
//  ICloudMigrationUseCase.swift
//  Reazy
//
//  Created by Claude on 7/19/26.
//

import Foundation
import UIKit

enum ICloudMigrationOperationError: Error {
    case sourceFileMissing
    case copyVerificationFailed
    case backgroundTimeExpired
}

/// 백그라운드 실행 유예 시간 만료를 만료 핸들러와 마이그레이션 루프 양쪽에서 안전하게 공유하고,
/// beginBackgroundTask/endBackgroundTask를 정확히 한 번씩만 짝지어 호출하기 위한 헬퍼
private final class BackgroundTaskGuard: @unchecked Sendable {
    private let lock = NSLock()
    private var identifier: UIBackgroundTaskIdentifier = .invalid
    private var _expired = false

    var expired: Bool {
        lock.lock(); defer { lock.unlock() }
        return _expired
    }

    func begin(name: String) {
        lock.lock()
        identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            self?.handleExpiration()
        }
        lock.unlock()
    }

    /// 마이그레이션 함수가 정상적으로(성공/실패 무관) 끝날 때 defer에서 호출
    func end() {
        lock.lock()
        let current = identifier
        identifier = .invalid
        lock.unlock()

        guard current != .invalid else { return }
        UIApplication.shared.endBackgroundTask(current)
    }

    /// iOS가 백그라운드 유예 시간을 다 써서 만료 핸들러가 호출된 경우에만 expired를 true로 표시
    private func handleExpiration() {
        lock.lock()
        _expired = true
        let current = identifier
        identifier = .invalid
        lock.unlock()

        guard current != .invalid else { return }
        UIApplication.shared.endBackgroundTask(current)
    }
}

struct ICloudMigrationLedger: Codable {
    struct MigratedRecord: Codable {
        /// 실제로 위치가 바뀐 경우에만 구 경로를 담는다. nil이면 해당 파일이 이미 목적지 디렉터리에
        /// 있었다는 뜻(예: 2단계의 iCloud 미가용 시 로컬 폴백으로 인해 플래그와 실제 위치가 어긋난 경우) —
        /// 이 경우 정리/롤백 대상에서 반드시 제외해야 새로 저장된(=구 파일과 동일한) 파일이 삭제되지 않는다.
        let oldURLPath: String?
        let oldFocusURLPath: String?
    }

    let targetEnabled: Bool
    let paperIDs: [UUID]
    var completed: [UUID: MigratedRecord]
}

protocol ICloudMigrationUseCase {
    /// 로컬 ↔ iCloud Drive 사이로 모든 논문 파일을 이동시키고, 완료 후에만 isICloudEnabled 플래그를 변경합니다
    func migrate(toICloud: Bool, progress: @escaping (_ completed: Int, _ total: Int) -> Void) async throws

    /// 완료되지 못한 마이그레이션을 원래 상태로 되돌립니다 (플래그는 애초에 바뀌지 않았으므로 건드리지 않음)
    func rollbackIncompleteMigration() async throws
}

final class DefaultICloudMigrationUseCase: ICloudMigrationUseCase {
    private let migrationRepository: ICloudMigrationRepository
    private let fileManager = FileManager.default

    init(migrationRepository: ICloudMigrationRepository) {
        self.migrationRepository = migrationRepository
    }

    func migrate(toICloud: Bool, progress: @escaping (Int, Int) -> Void) async throws {
        if let existing = loadLedger(), existing.targetEnabled != toICloud {
            try await rollbackIncompleteMigration()
        }

        if toICloud {
            guard fileManager.url(forUbiquityContainerIdentifier: "iCloud.com.chillin.reazy") != nil else {
                throw ICloudMigrationError.containerUnavailable
            }
        }

        var ledger = try loadOrCreateLedger(toICloud: toICloud)

        let bgTaskGuard = BackgroundTaskGuard()
        bgTaskGuard.begin(name: "ICloudMigration")
        defer { bgTaskGuard.end() }

        let total = ledger.paperIDs.count
        progress(ledger.completed.count, total)

        for id in ledger.paperIDs {
            if ledger.completed[id] != nil { continue }

            // 논문 단위 경계에서만 만료를 체크한다 — 복사 도중에 끊기지 않도록 보장
            if bgTaskGuard.expired {
                throw ICloudMigrationOperationError.backgroundTimeExpired
            }

            let record = try await migrateOnePaper(id: id, toICloud: toICloud)
            ledger.completed[id] = record
            saveLedger(ledger)
            progress(ledger.completed.count, total)
        }

        for (_, record) in ledger.completed {
            if let oldURLPath = record.oldURLPath {
                cleanupOldFile(at: oldURLPath)
            }
            if let oldFocusPath = record.oldFocusURLPath {
                cleanupOldFile(at: oldFocusPath)
            }
        }

        UserDefaults.standard.isICloudEnabled = toICloud
        clearLedger()
    }

    func rollbackIncompleteMigration() async throws {
        guard var ledger = loadLedger() else { return }

        for (id, record) in ledger.completed {
            try await revertOnePaper(id: id, record: record)
            ledger.completed.removeValue(forKey: id)
            saveLedger(ledger)
        }

        clearLedger()
    }

    // MARK: - Per-paper migration

    private func migrateOnePaper(id: UUID, toICloud: Bool) async throws -> ICloudMigrationLedger.MigratedRecord {
        let location = try fetchLocation(for: id)

        var isStale = false
        guard let oldURL = try? URL(resolvingBookmarkData: location.url, bookmarkDataIsStale: &isStale),
              fileManager.fileExists(atPath: oldURL.path) else {
            throw ICloudMigrationOperationError.sourceFileMissing
        }

        let destinationDir = try fileManager.pdfStorageDirectory(useICloud: toICloud)

        var createdDestinationURLs: [URL] = []

        do {
            let (newURL, newURLBookmark) = try copyAndBookmark(source: oldURL, toDirectory: destinationDir)
            // 파일이 이미 목적지 디렉터리에 있었다면(예: 2단계 iCloud 미가용 폴백으로 플래그와 실제 위치가
            // 어긋난 경우) 구 경로와 새 경로가 동일 — 이 경우 정리/롤백/실패 시 삭제 대상에서 모두 제외해야
            // 새로 저장된(=구 파일과 동일한) 파일이 지워지지 않는다
            let urlDidMove = oldURL.path != newURL.path
            if urlDidMove { createdDestinationURLs.append(newURL) }
            let oldURLPath: String? = urlDidMove ? oldURL.path : nil

            var newFocusBookmark: Data? = nil
            var oldFocusPath: String? = nil

            if let focusURLData = location.focusURL,
               let oldFocusURL = try? URL(resolvingBookmarkData: focusURLData, bookmarkDataIsStale: &isStale),
               fileManager.fileExists(atPath: oldFocusURL.path) {
                let (newFocusURL, bookmark) = try copyAndBookmark(source: oldFocusURL, toDirectory: destinationDir)
                let focusDidMove = oldFocusURL.path != newFocusURL.path
                if focusDidMove { createdDestinationURLs.append(newFocusURL) }
                newFocusBookmark = bookmark
                oldFocusPath = focusDidMove ? oldFocusURL.path : nil
            }

            let result = migrationRepository.updateFileLocation(id: id, url: newURLBookmark, focusURL: newFocusBookmark)
            if case .failure(let error) = result {
                throw error
            }

            return .init(oldURLPath: oldURLPath, oldFocusURLPath: oldFocusPath)
        } catch {
            // 방금 만든 목적지 복사본만 정리 — 구 파일/북마크는 그대로 안전하게 남아있음
            for url in createdDestinationURLs {
                try? fileManager.removeItem(at: url)
            }
            throw error
        }
    }

    private func revertOnePaper(id: UUID, record: ICloudMigrationLedger.MigratedRecord) async throws {
        var isStale = false
        let currentLocation = try fetchLocation(for: id)

        // oldURLPath가 nil이면 해당 필드는 애초에 이동하지 않았다는 뜻 — 현재 값 그대로 유지
        let restoredURLBookmark: Data
        if let oldURLPath = record.oldURLPath {
            guard fileManager.fileExists(atPath: oldURLPath) else {
                throw ICloudMigrationOperationError.sourceFileMissing
            }
            let oldURL = URL(fileURLWithPath: oldURLPath)
            restoredURLBookmark = try oldURL.bookmarkData(options: .suitableForBookmarkFile)

            // 마이그레이션 중 만든 새 위치 복사본을 정리
            if let currentURL = try? URL(resolvingBookmarkData: currentLocation.url, bookmarkDataIsStale: &isStale),
               currentURL.path != oldURL.path {
                try? fileManager.removeItem(at: currentURL)
            }
        } else {
            restoredURLBookmark = currentLocation.url
        }

        let restoredFocusBookmark: Data?
        if let oldFocusPath = record.oldFocusURLPath {
            guard fileManager.fileExists(atPath: oldFocusPath) else {
                throw ICloudMigrationOperationError.sourceFileMissing
            }
            restoredFocusBookmark = try URL(fileURLWithPath: oldFocusPath).bookmarkData(options: .suitableForBookmarkFile)

            if let focusData = currentLocation.focusURL,
               let currentFocusURL = try? URL(resolvingBookmarkData: focusData, bookmarkDataIsStale: &isStale),
               currentFocusURL.path != oldFocusPath {
                try? fileManager.removeItem(at: currentFocusURL)
            }
        } else {
            restoredFocusBookmark = currentLocation.focusURL
        }

        let result = migrationRepository.updateFileLocation(id: id, url: restoredURLBookmark, focusURL: restoredFocusBookmark)
        if case .failure(let error) = result {
            throw error
        }
    }

    // MARK: - File helpers

    private func copyAndBookmark(source: URL, toDirectory directory: URL) throws -> (URL, Data) {
        var destination = directory.appendingPathComponent(source.lastPathComponent)

        if fileManager.fileExists(atPath: destination.path) {
            let sourceSize = try? fileManager.attributesOfItem(atPath: source.path)[.size] as? Int
            let destSize = try? fileManager.attributesOfItem(atPath: destination.path)[.size] as? Int

            if let sourceSize, sourceSize == destSize {
                // 이미 복사되어 있음 (재개 상황) — 재복사 불필요
                let bookmark = try destination.bookmarkData(options: .suitableForBookmarkFile)
                return (destination, bookmark)
            }

            destination = try uniqueDestination(for: source, in: directory)
        }

        try fileManager.copyItem(at: source, to: destination)

        let sourceSize = try fileManager.attributesOfItem(atPath: source.path)[.size] as? Int
        let destSize = try fileManager.attributesOfItem(atPath: destination.path)[.size] as? Int
        guard sourceSize != nil, sourceSize == destSize else {
            try? fileManager.removeItem(at: destination)
            throw ICloudMigrationOperationError.copyVerificationFailed
        }

        let bookmark = try destination.bookmarkData(options: .suitableForBookmarkFile)
        return (destination, bookmark)
    }

    private func uniqueDestination(for source: URL, in directory: URL) throws -> URL {
        let ext = source.pathExtension
        let base = source.deletingPathExtension().lastPathComponent
        var num = 1
        while num < 9999 {
            let candidate = directory.appendingPathComponent("\(base) (\(num)).\(ext)")
            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            num += 1
        }
        throw ICloudMigrationOperationError.copyVerificationFailed
    }

    private func cleanupOldFile(at path: String) {
        guard fileManager.fileExists(atPath: path) else { return }
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            log("iCloud migration cleanup failed for \(path): \(error)")
        }
    }

    private func fetchLocation(for id: UUID) throws -> PaperFileLocation {
        let result = migrationRepository.fetchPaperLocation(id: id)
        switch result {
        case .success(let location):
            return location
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Ledger persistence

    private func loadLedger() -> ICloudMigrationLedger? {
        guard let data = UserDefaults.standard.icloudMigrationLedgerData else { return nil }
        return try? JSONDecoder().decode(ICloudMigrationLedger.self, from: data)
    }

    private func loadOrCreateLedger(toICloud: Bool) throws -> ICloudMigrationLedger {
        if let existing = loadLedger(), existing.targetEnabled == toICloud {
            return existing
        }

        let result = migrationRepository.fetchAllPaperLocations()
        let locations: [PaperFileLocation]
        switch result {
        case .success(let value):
            locations = value
        case .failure(let error):
            throw error
        }

        let ledger = ICloudMigrationLedger(
            targetEnabled: toICloud,
            paperIDs: locations.map { $0.id },
            completed: [:]
        )
        saveLedger(ledger)
        return ledger
    }

    private func saveLedger(_ ledger: ICloudMigrationLedger) {
        guard let data = try? JSONEncoder().encode(ledger) else { return }
        UserDefaults.standard.icloudMigrationLedgerData = data
    }

    private func clearLedger() {
        UserDefaults.standard.icloudMigrationLedgerData = nil
    }
}
