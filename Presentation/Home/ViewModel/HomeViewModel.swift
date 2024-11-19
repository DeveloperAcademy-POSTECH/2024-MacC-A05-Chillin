//
//  HomeViewModel.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published public var paperInfos: [PaperInfo] = []
    
    @Published public var rootFolders: [Folder] = []
    @Published public var currentFolder: Folder? = nil
    public var isAtRoot: Bool {
        return currentFolder == nil
    }
    
    @Published public var isLoading: Bool = false
    @Published public var memoText: String = ""
    
    private let homeViewUseCase: HomeViewUseCase
    
    init(homeViewUseCase: HomeViewUseCase) {
        self.homeViewUseCase = homeViewUseCase
        
        switch homeViewUseCase.loadPDFs() {
        case .success(let paperInfos):
            self.paperInfos = paperInfos
        case .failure(let error):
            print(error)
            return
        }
    }
}


extension HomeViewModel {
    public func uploadPDF(url: [URL]) -> UUID? {
        do {
            let paperInfo = try self.homeViewUseCase.uploadPDFFile(url: url)
            if paperInfo != nil {
                self.paperInfos.append(paperInfo!)
            }
            return paperInfo?.id
        } catch {
            print(error)
            return nil
        }
    }
    
    public func uploadSamplePDF() -> UUID? {
        let paperInfo = self.homeViewUseCase.uploadSamplePDFFile()
        
        if paperInfo != nil {
            self.paperInfos.append(paperInfo!)
        }
        
        return paperInfo?.id
    }
    
    public func deletePDF(ids: [UUID]) {
        self.homeViewUseCase.deletePDFs(id: ids)
        ids.forEach { id in
            self.paperInfos.removeAll(where: { $0.id == id })
        }
    }
}


extension HomeViewModel {
    public func updateMemo(at id: UUID, memo: String) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].memo = memo
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func deleteMemo(at id: UUID) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].memo = nil
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
}


extension HomeViewModel {
    public func updateFavorite(at id: UUID, isFavorite: Bool) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].isFavorite = isFavorite
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func updateFavorites(at ids: [UUID]) {
        ids.forEach { id in
            if let index = paperInfos.firstIndex(where: { $0.id == id }) {
                paperInfos[index].isFavorite = true
                self.homeViewUseCase.editPDF(paperInfos[index])
            }
        }
    }
    
    public func updateLastModifiedDate(at id: UUID, lastModifiedDate: Date) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].lastModifiedDate = lastModifiedDate
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func updateIsFigureSaved(at id: UUID, isFigureSaved: Bool) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].isFigureSaved = isFigureSaved
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func updateTitle(at id: UUID, title: String) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].title = title
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
}


extension HomeViewModel {
    public func uploadSampleData() {
        let sampleUrl = Bundle.main.url(forResource: "engPD5", withExtension: "pdf")!
        self.paperInfos.append(PaperInfo(
            title: "A review of the global climate change impacts, adaptation, and sustainable mitigation measures",
            thumbnail: .init(),
            url: try! Data(contentsOf: sampleUrl),
            isFavorite: false,
            memo: "test",
            isFigureSaved: false
        ))
    }
}

extension HomeViewModel {
    func filteringList(isFavoriteSelected: Bool) -> [FileSystemItem] {
        let currentFolders = currentFolder?.subFolders ?? rootFolders
        return isFavoriteSelected
        ? sortFavoriteLists(paperInfos: paperInfos, folders: currentFolders)
        : sortLists(paperInfos: paperInfos, folders: currentFolders)
    }
    
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

extension HomeViewModel {
    public func saveFolder(to parentFolder: Folder?, title: String, color: Color) {
        // TODO: - [브리] CoreData 연결 시 수정 필요
        let newFolder = self.homeViewUseCase.createFolder(to: parentFolder, title: title, color: color)
        
        if let parent = parentFolder {
            if parent.subFolders == nil {
                parent.subFolders = []
            }
            parent.subFolders?.append(newFolder)
        } else {
            rootFolders.append(newFolder)
        }
    }
    
    public func navigateToParent() {
        if let parent = currentFolder?.parentFolder {
            currentFolder = parent
        } else {
            currentFolder = nil
        }
    }
    
    public func navigateTo(folder: Folder) {
        currentFolder = folder
    }
}
