//
//  FileSystemItem.swift
//  Reazy
//
//  Created by 유지수 on 11/18/24.
//

import Foundation

enum FileSystemItem: Identifiable {
    case paper(PaperInfo)
    case folder(Folder)
    
    var id: UUID {
        switch self {
        case .paper(let paperInfo):
            return paperInfo.id
        case .folder(let folder):
            return folder.id
        }
    }
    
    var date: Date {
        switch self {
        case .paper(let paperInfo):
            return paperInfo.lastModifiedDate
        case .folder(let folder):
            return folder.createdAt
        }
    }
    
    var isFavorite: Bool {
        switch self {
        case .paper(let paperInfo):
            return paperInfo.isFavorite
        case .folder(let folder):
            return folder.isFavorite
        }
    }
}
