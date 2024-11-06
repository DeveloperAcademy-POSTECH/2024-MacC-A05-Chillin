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
    var dateTime: String
    var author: String
    var year: String
    let pages: Int
    let publisher: String
    let thumbnail: Data
    let url: String
    let lastModifiedDate: Date
    var isFavorite: Bool
    
    init(
        id: UUID = .init(),
        title: String,
        datetime: String,
        author: String,
        year: String,
        pages: Int,
        publisher: String,
        thumbnail: Data,
        url: String,
        lastModifiedDate: Date = .init(),
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.dateTime = datetime
        self.author = author
        self.year = year
        self.pages = pages
        self.publisher = publisher
        self.thumbnail = thumbnail
        self.url = url
        self.lastModifiedDate = lastModifiedDate
        self.isFavorite = isFavorite
    }
}
