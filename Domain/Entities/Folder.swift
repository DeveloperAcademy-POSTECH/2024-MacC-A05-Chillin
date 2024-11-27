//
//  Folder.swift
//  Reazy
//
//  Created by 유지수 on 11/18/24.
//

import Foundation
import SwiftUI

/**
 폴더 구조
 : 계층 구조 구현 및 폴더 탐색기를 위한 class 구현
 */
struct Folder: Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var color: String
    var memo: String?
    var isFavorite: Bool
    
    var parentFolderID: UUID?
    
    init(
        id: UUID,
        title: String,
        createdAt: Date = Date(),
        color: String,
        memo: String? = nil,
        isFavorite: Bool = false,
        parentFolderID: UUID?
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.color = color
        self.memo = memo
        self.isFavorite = isFavorite
        self.parentFolderID = parentFolderID
    }
}
