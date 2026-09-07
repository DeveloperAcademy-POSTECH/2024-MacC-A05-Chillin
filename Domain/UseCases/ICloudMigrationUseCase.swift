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

    /// UIApplication은 메인 액터 전용이므로, 백그라운드에서 도는 마이그레이션 루프에서 직접 만지지 않는다
    func begin(name: String) async {
        let newIdentifier = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
                self?.handleExpiration()
            }
        }

        lock.lock()
        identifier = newIdentifier
        lock.unlock()
    }

    /// 마이그레이션 함수가 정상적으로(성공/실패 무관) 끝날 때 defer에서 호출
    func end() {
        lock.lock()
        let current = identifier
        identifier = .invalid
        lock.unlock()

        guard current != .invalid else { return }
        DispatchQueue.main.async {
            UIApplication.shared.endBackgroundTask(current)
        }
    }

    /// iOS가 백그라운드 유예 시간을 다 써서 만료 핸들러가 호출된 경우에만 expired를 true로 표시
    private func handleExpiration() {
        lock.lock()
        _expired = true
        let current = identifier
        identifier = .invalid
        lock.unlock()

        guard current != .invalid else { return }
        DispatchQueue.main.async {
            UIApplication.shared.endBackgroundTask(current)
        }
    }
}

struct ICloudMigrationLedger: Codable {
    struct MigratedRecord: Codable {
        /// 실제로 위치가 바뀐 경우에만 구 경로를 담는다. nil이면 해당 파일이 이미 목적지 디렉터리에
        /// 있었다는 뜻(예: 2단계의 iCloud 미가용 시 로컬 폴백으로 인해 플래그와 실제 위치가 어긋난 경우) —
        /// 이 경우 정리/롤백 대상에서 반드시 제외해야 새로 저장된(=구 파일과 동일한) 파일이 삭제되지 않는다.
        let oldURLPath: String?
        let oldFocusURLPath: String?

        /// 이번 마이그레이션이 실제로 만든 목적지 경로. 재개할 때 이 값이 있으면
        /// 파일 크기 비교로 "이미 복사됨"을 넘겨짚지 않고 기록된 경로를 그대로 쓴다
        var newURLPath: String? = nil
        var newFocusURLPath: String? = nil
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
        await bgTaskGuard.begin(name: "ICloudMigration")
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

        guard let oldURL = PaperFileLocator.resolve(
            relativePath: location.relativePath,
            bookmark: location.url,
            title: location.title
        )?.url else {
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
            var newFocusURL: URL? = nil
            var oldFocusPath: String? = nil

            if let oldFocusURL = PaperFileLocator.resolve(
                relativePath: location.focusRelativePath,
                bookmark: location.focusURL,
                title: nil
            )?.url {
                let (focusDestination, bookmark) = try copyAndBookmark(source: oldFocusURL, toDirectory: destinationDir)
                let focusDidMove = oldFocusURL.path != focusDestination.path
                if focusDidMove { createdDestinationURLs.append(focusDestination) }
                newFocusBookmark = bookmark
                newFocusURL = focusDestination
                oldFocusPath = focusDidMove ? oldFocusURL.path : nil
            }

            // 목적지 디렉터리 기준 상대 경로. 플래그는 아직 안 바뀌었으므로 destinationDir을 직접 기준으로 삼는다
            let newRelativePath = PaperFileLocator.storageRelativePath(of: newURL, in: destinationDir)
            let newFocusRelativePath = newFocusURL.flatMap {
                PaperFileLocator.storageRelativePath(of: $0, in: destinationDir)
            }

            let result = migrationRepository.updateFileLocation(
                id: id,
                url: newURLBookmark,
                relativePath: newRelativePath,
                focusURL: newFocusBookmark,
                focusRelativePath: newFocusRelativePath
            )
            if case .failure(let error) = result {
                throw error
            }

            return .init(
                oldURLPath: oldURLPath,
                oldFocusURLPath: oldFocusPath,
                newURLPath: newURL.path,
                newFocusURLPath: newFocusURL?.path
            )
        } catch {
            // 방금 만든 목적지 복사본만 정리 — 구 파일/북마크는 그대로 안전하게 남아있음
            for url in createdDestinationURLs {
                try? fileManager.removeItem(at: url)
            }
            throw error
        }
    }

    private func revertOnePaper(id: UUID, record: ICloudMigrationLedger.MigratedRecord) async throws {
        let currentLocation = try fetchLocation(for: id)

        // oldURLPath가 nil이면 해당 필드는 애초에 이동하지 않았다는 뜻 — 현재 값 그대로 유지
        let restoredURLBookmark: Data
        if let oldURLPath = record.oldURLPath {
            guard fileManager.fileExists(atPath: oldURLPath) else {
                throw ICloudMigrationOperationError.sourceFileMissing
            }
            let oldURL = URL(fileURLWithPath: oldURLPath)
            restoredURLBookmark = try oldURL.bookmarkData(options: .suitableForBookmarkFile)

            // 마이그레이션 중 만든 새 위치 복사본을 정리 — 원장에 기록해 둔 경로를 그대로 쓴다
            if let newURLPath = record.newURLPath, newURLPath != oldURL.path {
                try? fileManager.removeItem(atPath: newURLPath)
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

            if let newFocusURLPath = record.newFocusURLPath, newFocusURLPath != oldFocusPath {
                try? fileManager.removeItem(atPath: newFocusURLPath)
            }
        } else {
            restoredFocusBookmark = currentLocation.focusURL
        }

        // 롤백 시점에는 플래그가 아직 안 바뀌었으므로, 현재 저장소 기준으로 상대 경로를 다시 계산한다.
        // 저장소 밖의 파일이면 nil이 되고, 그 경우 북마크 폴백이 그대로 동작한다
        let restoredRelativePath = record.oldURLPath.flatMap {
            PaperFileLocator.storageRelativePath(of: URL(fileURLWithPath: $0))
        } ?? currentLocation.relativePath

        let restoredFocusRelativePath = record.oldFocusURLPath.flatMap {
            PaperFileLocator.storageRelativePath(of: URL(fileURLWithPath: $0))
        } ?? currentLocation.focusRelativePath

        let result = migrationRepository.updateFileLocation(
            id: id,
            url: restoredURLBookmark,
            relativePath: restoredRelativePath,
            focusURL: restoredFocusBookmark,
            focusRelativePath: restoredFocusRelativePath
        )
        if case .failure(let error) = result {
            throw error
        }
    }

    // MARK: - File helpers

    private func copyAndBookmark(source: URL, toDirectory directory: URL) throws -> (URL, Data) {
        var destination = directory.appendingPathComponent(source.lastPathComponent)

        if fileManager.fileExists(atPath: destination.path) {
            if isSameFile(source, destination) {
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

    /// 목적지에 이미 있는 파일이 정말 이 논문의 파일인지 판별한다.
    /// 크기만 비교하면, 다른 기기가 올려둔 같은 이름의 파일이 우연히 크기까지 같을 때
    /// 남의 파일을 내 논문으로 연결해 버린다 — 앞부분 내용까지 함께 확인한다
    private func isSameFile(_ lhs: URL, _ rhs: URL) -> Bool {
        guard let lhsSize = fileSize(of: lhs),
              let rhsSize = fileSize(of: rhs),
              lhsSize == rhsSize else {
            return false
        }

        guard let lhsHead = headChunk(of: lhs), let rhsHead = headChunk(of: rhs) else {
            // 읽을 수 없으면(예: 아직 내려받지 않은 iCloud 파일) 같다고 단정하지 않는다.
            // 새 이름으로 복사되어 사본이 하나 생길 뿐, 기존 파일을 덮어쓰지는 않는다
            return false
        }

        return lhsHead == rhsHead
    }

    private func fileSize(of url: URL) -> Int? {
        (try? fileManager.attributesOfItem(atPath: url.path))?[.size] as? Int
    }

    /// 파일 앞부분만 읽어 비교한다. 전체를 읽으면 iCloud 파일을 통째로 내려받게 된다
    private func headChunk(of url: URL, limit: Int = 64 * 1024) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        return try? handle.read(upToCount: limit)
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
