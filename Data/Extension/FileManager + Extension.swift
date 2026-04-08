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

