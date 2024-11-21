//
//  FileManager + Extension.swift
//  Reazy
//
//  Created by 문인범 on 11/20/24.
//

import Foundation

/**
 파일 중복 확인 후 rename하는 메소드
 */
extension FileManager {
    func renameFile(fileURL: URL, to fileName: String) -> Bool {
        let newUrl = fileURL.deletingLastPathComponent().appending(path: fileName + ".pdf")
        
        guard !fileExists(atPath: newUrl.path()) else { return false }
        
        do {
            try copyItem(at: fileURL, to: newUrl)
            try removeItem(at: fileURL)
        } catch {
            print(error)
            return false
        }
        
        return true
    }
}
