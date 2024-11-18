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
class Folder {
    let id: UUID
    var title: String
    var createdAt: Date
    var color: Color
    var memo: String?
    var isFavorite: Bool
    
    weak var parentFolder: Folder?
    var subFolders: [Folder]?
    var documents: [PaperInfo]?
    
    init(
        id: UUID = .init(),
        title: String,
        createdAt: Date = Date(),
        color: Color,
        memo: String? = nil,
        isFavorite: Bool = false,
        parentFolder: Folder? = nil,
        subFolders: [Folder]? = nil,
        documents: [PaperInfo]? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.color = color
        self.memo = memo
        self.isFavorite = isFavorite
        self.parentFolder = parentFolder
        self.subFolders = subFolders
        self.documents = documents
    }
}
