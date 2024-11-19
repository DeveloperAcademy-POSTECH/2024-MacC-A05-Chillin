//
//  PaperInfo.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import Foundation

// 임의 모델 생성
struct PaperInfo {
    let id: UUID
    var title: String
    let thumbnail: Data
    let url: Data
    var lastModifiedDate: Date
    var isFavorite: Bool
    var memo: String?
    var isFigureSaved: Bool
    
    init(
        id: UUID = .init(),
        title: String,
        thumbnail: Data,
        url: Data,
        lastModifiedDate: Date = .init(),
        isFavorite: Bool = false,
        memo: String? = nil,
        isFigureSaved: Bool = false
    ) {
        self.id = id
        self.title = title
        self.thumbnail = thumbnail
        self.url = url
        self.lastModifiedDate = lastModifiedDate
        self.isFavorite = isFavorite
        self.memo = memo
        self.isFigureSaved = isFigureSaved
    }
}