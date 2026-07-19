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
extension FileManager {
    /// PDF 저장 기준 디렉토리.
    /// iCloud 동기화 플래그가 켜져 있으면 iCloud Drive 컨테이너의 Documents 하위 폴더를,
    /// 꺼져 있으면(기본값) 기존과 동일한 로컬 샌드박스 Documents 디렉토리를 반환한다.
    var pdfStorageDirectory: URL {
        guard UserDefaults.standard.isICloudEnabled else {
            return self.urls(for: .documentDirectory, in: .userDomainMask).first!
        }

        guard let ubiquityContainerURL = self.url(forUbiquityContainerIdentifier: "iCloud.com.chillin.reazy") else {
            // iCloud 미로그인 등으로 컨테이너를 가져올 수 없는 경우, 로컬 Documents로 안전하게 폴백
            log("iCloud container unavailable, falling back to local Documents directory")
            return self.urls(for: .documentDirectory, in: .userDomainMask).first!
        }

        let icloudDocumentsURL = ubiquityContainerURL.appendingPathComponent("Documents")

        if !self.fileExists(atPath: icloudDocumentsURL.path()) {
            do {
                try self.createDirectory(at: icloudDocumentsURL, withIntermediateDirectories: true)
            } catch {
                log("failed to create iCloud Documents directory: \(error)")
                return self.urls(for: .documentDirectory, in: .userDomainMask).first!
            }
        }

        return icloudDocumentsURL
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

