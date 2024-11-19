//
//  PaperListViewModel.swift
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

class PaperListViewModel: ObservableObject {
    /// 전체 리스트
    func sortLists(paperInfos: [PaperInfo], folders: [Folder]) -> [FileSystemItem] {
        // PaperInfo와 Folder를 FileSystemItem으로 변환
        let paperItems = paperInfos.map { FileSystemItem.paper($0) }
        let folderItems = folders.map { FileSystemItem.folder($0) }
        
        // 두 리스트를 합치고 날짜 순서대로 정렬
        let combinedItems = paperItems + folderItems
        return combinedItems.sorted(by: { $0.date > $1.date })
    }
    
    /// 즐겨찾기 리스트
    func sortFavoriteLists(paperInfos: [PaperInfo], folders: [Folder]) -> [FileSystemItem] {
        let paperItems = paperInfos.map { FileSystemItem.paper($0) }
        let folderItems = folders.map { FileSystemItem.folder($0) }
        
        let combinedItems = paperItems + folderItems
        return combinedItems.filter { $0.isFavorite }.sorted(by: { $0.date > $1.date })
    }
}
