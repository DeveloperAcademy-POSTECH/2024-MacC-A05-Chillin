//
//  PaperInfo.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import Foundation

struct PaperInfo {
    let id: UUID
    var title: String
    let thumbnail: Data
    var url: Data
    var focusURL: Data?
    var lastModifiedDate: Date
    var isFavorite: Bool
    var memo: String?
    var isFigureSaved: Bool
    
    var folderID: UUID?
    var tags: [Tag]
    
    init(
        id: UUID = .init(),
        title: String,
        thumbnail: Data,
        url: Data,
        focusURL: Data? = nil,
        lastModifiedDate: Date = .init(),
        isFavorite: Bool = false,
        memo: String? = nil,
        isFigureSaved: Bool = false,
        folderID: UUID? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.title = title
        self.thumbnail = thumbnail
        self.url = url
        self.focusURL = focusURL
        self.lastModifiedDate = lastModifiedDate
        self.isFavorite = isFavorite
        self.memo = memo
        self.isFigureSaved = isFigureSaved
        self.folderID = folderID
        self.tags = tags
    }
}
