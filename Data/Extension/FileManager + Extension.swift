//
//  FileManager + Extension.swift
//  Reazy
//
//  Created by 문인범 on 11/20/24.
//

import Foundation
import SwiftUI

/**
 파일 중복 확인 후 rename하는 메소드
 */
enum ICloudMigrationError: Error {
    case containerUnavailable
}

extension FileManager {
    /// PDF 저장 기준 디렉토리를 명시적으로 지정된 저장소 기준으로 반환한다.
    /// useICloud가 true인데 iCloud 컨테이너를 가져올 수 없으면(미로그인 등) 조용히 폴백하지 않고 에러를 던진다.
    /// 마이그레이션처럼 "실제로 iCloud로 이동했는지"가 중요한 호출부에서 사용한다.
    func pdfStorageDirectory(useICloud: Bool) throws -> URL {
        guard useICloud else {
            return self.urls(for: .documentDirectory, in: .userDomainMask).first!
        }

        guard let ubiquityContainerURL = self.url(forUbiquityContainerIdentifier: "iCloud.com.chillin.reazy") else {
            throw ICloudMigrationError.containerUnavailable
        }

        let icloudDocumentsURL = ubiquityContainerURL.appendingPathComponent("Documents")

        if !self.fileExists(atPath: icloudDocumentsURL.path()) {
            try self.createDirectory(at: icloudDocumentsURL, withIntermediateDirectories: true)
        }

        return icloudDocumentsURL
    }

    /// PDF 저장 기준 디렉토리.
    /// iCloud 동기화 플래그가 켜져 있으면 iCloud Drive 컨테이너의 Documents 하위 폴더를,
    /// 꺼져 있으면(기본값) 기존과 동일한 로컬 샌드박스 Documents 디렉토리를 반환한다.
    /// iCloud 컨테이너를 가져올 수 없는 경우 로컬 Documents로 안전하게 폴백한다.
    var pdfStorageDirectory: URL {
        do {
            return try pdfStorageDirectory(useICloud: UserDefaults.standard.isICloudEnabled)
        } catch {
            log("iCloud container unavailable (\(error)), falling back to local Documents directory")
            return self.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
    }

    func renameFile(fileURL: URL, to fileName: String) -> Bool {
        let newUrl = fileURL.deletingLastPathComponent().appending(path: fileName + ".pdf")
        
        guard !fileExists(atPath: newUrl.path()) else { return false }
        
        do {
            try moveItem(at: fileURL, to: newUrl)
        } catch {
            log(error)
            return false
        }
        
        return true
    }
}

extension Character {
    var isHangul: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return (scalar.value >= 0xAC00 && scalar.value <= 0xD7AF) ||
               (scalar.value >= 0x1100 && scalar.value <= 0x11FF) ||
               (scalar.value >= 0x3130 && scalar.value <= 0x318F)
    }
    
    var isEnglish: Bool {
        guard unicodeScalars.first != nil else { return false }
        return ("a"..."z").contains(self) || ("A"..."Z").contains(self)
    }
}

