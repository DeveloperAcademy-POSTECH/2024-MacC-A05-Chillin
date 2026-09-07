//
//  PaperFileLocator.swift
//  Reazy
//
//  Created by Claude on 9/7/26.
//

import Foundation

/**
 논문 파일의 실제 위치를 찾는 단일 진입점.

 기존에는 각 화면이 직접 북마크(`PaperData.url`)를 풀어 경로를 얻었는데, 북마크에는
 그 기기의 볼륨 UUID와 샌드박스 절대 경로가 들어 있어 CloudKit으로 복제되면 다른 기기에서는
 해석되지 않는다. 그래서 저장소 기준 상대 경로(`relativePath`)를 우선 사용하고,
 북마크는 폴백으로만 쓴다.

 상대 경로가 아직 비어 있는 논문(백필 전이거나 예전에 저장된 것)도 2·3단계에서 살아나므로,
 이 타입을 거치는 한 기존 사용자의 논문이 열리지 않게 되는 일은 없다.
 */
enum PaperFileLocator {

    struct Resolution {
        let url: URL

        /// 이번 해석으로 새로 알아낸 상대 경로. nil이 아니면 CoreData에 반영해 두면
        /// 다음부터는 1단계에서 바로 찾는다 (자가 치유)
        let repairedRelativePath: String?
    }

    /// 1) 상대 경로 → 2) 북마크 → 3) 제목 기반 파일명 추정 순으로 시도한다
    static func resolve(relativePath: String?, bookmark: Data?, title: String?) -> Resolution? {
        let fileManager = FileManager.default
        let storageDirectory = fileManager.pdfStorageDirectory

        // 1단계: 저장소 기준 상대 경로.
        // 기기마다 다른 앞부분을 그 기기의 저장소 경로로 조립하므로 어느 기기에서도 통한다
        if let relativePath, !relativePath.isEmpty {
            let candidate = storageDirectory.appending(path: relativePath)
            if fileManager.fileExists(atPath: candidate.path) {
                return .init(url: candidate, repairedRelativePath: nil)
            }
        }

        // 2단계: 북마크. 백필 전이거나, 파일이 저장소 밖에 있는 경우
        if let bookmark {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &isStale),
               fileManager.fileExists(atPath: url.path) {
                return .init(url: url, repairedRelativePath: storageRelativePath(of: url, in: storageDirectory))
            }
        }

        // 3단계: 북마크까지 깨졌을 때의 마지막 복구 시도.
        // 업로드 시 제목을 파일명에서 만들기 때문에 대개 일치하지만, 사용자가 논문 이름을
        // 바꿔도 파일명은 그대로라 어긋날 수 있다 — best-effort로만 취급한다
        if let title, !title.isEmpty {
            let candidate = storageDirectory.appending(path: "\(title).pdf")
            if fileManager.fileExists(atPath: candidate.path) {
                return .init(url: candidate, repairedRelativePath: candidate.lastPathComponent)
            }
        }

        return nil
    }

    /// 파일이 저장소 디렉터리 안에 있으면 그 기준 상대 경로를, 밖에 있으면 nil을 돌려준다
    static func storageRelativePath(of url: URL, in directory: URL) -> String? {
        let directoryPath = directory.standardizedFileURL.path
        let filePath = url.standardizedFileURL.path

        guard filePath.hasPrefix(directoryPath + "/") else { return nil }
        return String(filePath.dropFirst(directoryPath.count + 1))
    }

    /// 현재 저장소 기준으로 상대 경로를 계산한다 (파일을 새로 저장한 직후 기록용)
    static func storageRelativePath(of url: URL) -> String? {
        storageRelativePath(of: url, in: FileManager.default.pdfStorageDirectory)
    }
}

// MARK: - PaperInfo 편의 메소드

extension PaperFileLocator {
    static func resolve(_ paperInfo: PaperInfo) -> Resolution? {
        resolve(
            relativePath: paperInfo.relativePath,
            bookmark: paperInfo.url,
            title: paperInfo.title
        )
    }

    /// 집중 모드용 PDF. 제목 기반 추정은 원본 파일과 이름이 달라 의미가 없으므로 쓰지 않는다
    static func resolveFocus(_ paperInfo: PaperInfo) -> Resolution? {
        guard paperInfo.focusURL != nil || paperInfo.focusRelativePath != nil else { return nil }

        return resolve(
            relativePath: paperInfo.focusRelativePath,
            bookmark: paperInfo.focusURL,
            title: nil
        )
    }
}
