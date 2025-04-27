//
//  PaperInfo.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import Foundation
import UIKit
import CoreTransferable

struct PaperInfo: Identifiable, Hashable, Codable, Transferable {
    
    let id: UUID
    var title: String
    let thumbnail: Data
    var url: Data
    var focusURL: Data?
    var lastModifiedDate: Date
    var isFavorite: Bool
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
        self.isFigureSaved = isFigureSaved
        self.folderID = folderID
        self.tags = tags
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
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
            isFigureSaved: false,
            folderID: nil,
            tags: []
        )
    }
}
