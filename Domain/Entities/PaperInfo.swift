//
//  PaperInfo.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import Foundation
import UIKit

// 임의 모델 생성
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
        folderID: UUID? = nil
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
    }
    
    public static var sampleData: Self {
        let url = try! Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!.bookmarkData()
        let thumbnail = UIImage(resource: .testThumbnail).pngData()!
        
        return .init(
            id: .init(),
            title: "개간지 나는 논문",
            thumbnail: thumbnail,
            url: url,
            focusURL: nil,
            lastModifiedDate: .now,
            isFavorite: false,
            memo: nil,
            isFigureSaved: false,
            folderID: nil
        )
    }
}
