//
//  PaperFileLocation.swift
//  Reazy
//
//  Created by Claude on 7/19/26.
//

import Foundation

struct PaperFileLocation {
    let id: UUID
    let title: String
    let url: Data
    let relativePath: String?
    let focusURL: Data?
    let focusRelativePath: String?
}
