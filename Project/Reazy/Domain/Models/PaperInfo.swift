//
//  PaperInfo.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import Foundation

// 임의 모델 생성
struct PaperInfo {
    let title: String
    let dateTime: String
    let author: String
    let year: String
    let pages: Int
    let publisher: String
    let thumbnail: Data
    let url: String
    
    init(title: String, datetime: String, author: String, year: String, pages: Int, publisher: String, thumbnail: Data, url: String) {
        self.title = title
        self.dateTime = datetime
        self.author = author
        self.year = year
        self.pages = pages
        self.publisher = publisher
        self.thumbnail = thumbnail
        self.url = url
    }
}
