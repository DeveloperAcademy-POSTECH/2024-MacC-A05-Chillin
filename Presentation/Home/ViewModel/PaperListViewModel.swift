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
}

class PaperListViewModel: ObservableObject {
    func sortLists(paperInfos: [PaperInfo], folders: [Folder]) -> [FileSystemItem] {
        // PaperInfo와 Folder를 FileSystemItem으로 변환
        let paperItems = paperInfos.map { FileSystemItem.paper($0) }
        let folderItems = folders.map { FileSystemItem.folder($0) }
        
        // 두 리스트를 합치고 날짜 순서대로 정렬
        let combinedItems = paperItems + folderItems
        return combinedItems.sorted(by: { $0.date > $1.date })
    }
}
