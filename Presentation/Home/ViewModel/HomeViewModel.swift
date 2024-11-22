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
    @Published public var paperInfos: [PaperInfo] = [] {
        didSet {
            updateFilteredList()
        }
    }
    
    // 전체 폴더 배열
    @Published public var folders: [Folder] = [] {
        didSet {
            updateFilteredList()
        }
    }
    
    // 현재 위치한 폴더
    @Published public var currentFolder: Folder? = nil {
        didSet {
            updateFilteredList()
        }
    }
    public var isAtRoot: Bool {
        return currentFolder == nil
    }
    @Published var filteredLists: [FileSystemItem] = []
    
    @Published public var isFavoriteSelected: Bool = false {
        didSet {
            resetToRoot()
            updateFilteredList()
        }
    }
    
    // 진입 경로 추적 스택
    private var navigationStack: [(isFavoriteSelected: Bool, folder: Folder?)] = []
    
    @Published public var isLoading: Bool = false
    @Published public var memoText: String = ""
    @Published public var isErrorOccured: Bool = false
    @Published public var errorStatus: PDFUploadError = .failedToAccessingSecurityScope
    
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
        
        switch homeViewUseCase.loadFolders() {
        case .success(let folders):
            self.folders = folders
        case .failure(let error):
            print(error)
            return
        }
        
        updateFilteredList()
    }
}


extension HomeViewModel {
    public func uploadPDF(url: [URL]) -> UUID? {
        do {
            let currentFolderID = currentFolder?.id
            
            let paperInfo = try self.homeViewUseCase.uploadPDFFile(url: url, folderID: currentFolderID)
            if paperInfo != nil {
                self.paperInfos.append(paperInfo!)
            }
            return paperInfo?.id
        } catch {
            if let error = error as? PDFUploadError {
                self.errorStatus = error
            }
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
    
    public func deletePDF(at id: UUID) {
        self.homeViewUseCase.deletePDF(id: id)
        self.paperInfos.removeAll(where: { $0.id == id })
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
    public func updatePaperFavorite(at id: UUID, isFavorite: Bool) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].isFavorite = isFavorite
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func updatePaperFavorites(at ids: [UUID]) {
        ids.forEach { id in
            if let index = paperInfos.firstIndex(where: { $0.id == id }) {
                paperInfos[index].isFavorite = true
                self.homeViewUseCase.editPDF(paperInfos[index])
            }
        }
    }
    
    public func updatePaperLocation(at id: UUID, folderID: UUID?) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].folderID = folderID
            self.homeViewUseCase.editPDF(paperInfos[index])
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
            var changablePaper = paperInfos[index]
            changablePaper.title = title
            let result = self.homeViewUseCase.editPDF(changablePaper)
            
            switch result {
            case .success:
                paperInfos[index].title = title
            case .failure(let error):
                print(error)
                self.errorStatus = .fileNameDuplication
                self.isErrorOccured.toggle()
                break
            }
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
            isFigureSaved: false,
            folderID: nil
        ))
    }
}

extension HomeViewModel {
    func updateFilteredList() {
        if isFavoriteSelected {
            filteredLists = filteringFavList()
        } else {
            filteredLists = filteringList()
        }
    }
        
    func filteringList() -> [FileSystemItem] {
        var currentFolders: [Folder] {
            guard let folder = currentFolder else {
                return folders.filter { $0.parentFolderID == nil }
            }
            return folders.filter { $0.parentFolderID == folder.id }
        }
        
        var currentDocuments: [PaperInfo] {
            guard let folder = currentFolder else {
                return paperInfos.filter { $0.folderID == nil }
            }
            return paperInfos.filter { $0.folderID == folder.id }
        }
        
        return sortLists(paperInfos: currentDocuments, folders: currentFolders)
    }
    
    func filteringFavList() -> [FileSystemItem] {
        if let folder = currentFolder {
            // 현재 선택된 폴더가 있을 경우, 해당 폴더의 모든 문서를 반환
            let folderDocuments = paperInfos.filter { $0.folderID == folder.id }
            let folders = folders.filter { $0.parentFolderID == folder.id }
            return sortLists(paperInfos: folderDocuments, folders: folders)
        } else {
            // 즐겨찾기 필터
            let paperItems = paperInfos.map { FileSystemItem.paper($0) }
            let folderItems = folders.map { FileSystemItem.folder($0) }
            
            let combinedItems = paperItems + folderItems
            return combinedItems.filter { $0.isFavorite }.sorted(by: { $0.date > $1.date })
        }
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
}

extension HomeViewModel {
    public func createFolder(to parentFolderID: UUID?, title: String, color: String) -> Folder {
        let folder = Folder(
            id: UUID(),
            title: title,
            color: color,
            parentFolderID: parentFolderID
        )
        
        return folder
    }
    
    public func saveFolder(to parentFolderID: UUID?, title: String, color: String) {
        let newFolder = self.createFolder(to: parentFolderID, title: title, color: color)
        
        self.homeViewUseCase.saveFolder(newFolder)
        folders.append(newFolder)
    }
    
    public func updateFolderInfo(at id: UUID, title: String, color: String) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].title = title
            folders[index].color = color
            self.homeViewUseCase.editFolder(folders[index])
        }
    }
    
    public func updateFolderFavorite(at id: UUID, isFavorite: Bool) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].isFavorite = isFavorite
            self.homeViewUseCase.editFolder(folders[index])
        }
    }
    
    public func updateFolderFavorites(at ids: [UUID]) {
        ids.forEach { id in
            if let index = folders.firstIndex(where: { $0.id == id }) {
                folders[index].isFavorite = true
                self.homeViewUseCase.editFolder(folders[index])
            }
        }
    }
    
    public func updateFolderLocation(at id: UUID, folderID: UUID?) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].parentFolderID = folderID
            self.homeViewUseCase.editFolder(folders[index])
        }
    }
    
    public func deleteFolder(at id: UUID) {
        self.homeViewUseCase.deleteFolder(id: id)
        self.folders.removeAll(where: { $0.id == id })
    }
}

extension HomeViewModel {
    public func navigateToParent() {
        if isFavoriteSelected {
            // 즐겨찾기 경로를 스택에서 복원
            if let lastState = navigationStack.popLast() {
                isFavoriteSelected = lastState.isFavoriteSelected
                currentFolder = lastState.folder
            } else {
                // 기본 상태로 복원
                isFavoriteSelected = true
                currentFolder = nil
            }
        } else {
            // 전체 탭에서는 부모 폴더로 이동
            if let parentID = currentFolder?.parentFolderID {
                currentFolder = folders.first { $0.id == parentID }
            } else {
                currentFolder = nil
            }
        }
    }
    
    public func navigateTo(folder: Folder) {
        if isFavoriteSelected {
            navigationStack.append((isFavoriteSelected: isFavoriteSelected, folder: currentFolder))
        }
        currentFolder = folder
    }
    
    // 탭 변경 시 최초 상태로 초기화
    private func resetToRoot() {
        currentFolder = nil
        navigationStack.removeAll()
    }
    
    var parentFolderTitle: String? {
        if isFavoriteSelected {
            // 즐겨찾기 경로에서는 스택의 마지막 폴더를 확인
            return navigationStack.last?.folder?.title
        } else {
            // 전체 경로에서는 현재 폴더의 부모 폴더를 확인
            guard let parentID = currentFolder?.parentFolderID else {
                return nil
            }
            return folders.first { $0.id == parentID }?.title
        }
    }
}

extension HomeViewModel {
    public func deleteFiles(_ items: [FileSystemItem]) {
        for item in items {
            switch item {
            case .paper(let paperInfo):
                self.homeViewUseCase.deletePDF(id: paperInfo.id)
                self.paperInfos.removeAll(where: { $0.id == paperInfo.id })
            case .folder(let folder):
                self.homeViewUseCase.deleteFolder(id: folder.id)
                self.folders.removeAll(where: { $0.id == folder.id })
            }
        }
    }
}
