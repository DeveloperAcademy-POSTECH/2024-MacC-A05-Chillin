//
//  HomeViewModel.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    private let pdfSharedData: PDFSharedData = .shared
    
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
    
    // 폴더 이동 화면에서 새 폴더 생성했을 경우 Focus하기 위한 변수
    @Published public var newFolderParentID: UUID?
    @Published public var newFolderID: UUID?
    
    public var isAtRoot: Bool {
        return currentFolder == nil
    }
    
    @Published var selectedFolderID: UUID? {
        didSet {
            updateFilteredList()
        }
    }
    
    @Published public var isFavoriteSelected: Bool = false {
        didSet {
            resetToRoot()
            updateFilteredList()
        }
    }
    @Published public var isTagSelected: Bool = false {
        didSet {
            resetToRoot()
            updateFilteredList()
        }
    }
    @Published public var isMainSelected: Bool = true {
        didSet {
            updateFilteredList()
        }
    }
    
    @Published var filteredLists: [PaperInfo] = []
    
    @Published var isMovingFolder: Bool = false
    @Published var selectedItems: Set<UUID> = []
    
    @Published public var isSearching: Bool = false
    @Published public var searchText: String = ""
    
    @Published public var isEditing: Bool = false

    @Published public var selectedMenu: Options = .main
    
    public var changedTitle: String?
    
    // 진입 경로 추적 스택
    private var navigationStack: [(isFavoriteSelected: Bool, folder: Folder?)] = []
    
    @Published public var isLoading: Bool = false
    @Published public var isErrorOccured: Bool = false
    @Published public var errorStatus: PDFUploadError = .failedToAccessingSecurityScope
    
    @Published public var isSettingMenu: Bool = false
    @Published public var viewStatus: SearchViewStatus = .normal
    public var isInHomeView: Bool = true
    
    private let homeViewUseCase: HomeViewUseCase
    
    private var cancellables: Set<AnyCancellable> = []
    
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
        setBinding()
    }
    
    deinit {
        self.cancellables.forEach { $0.cancel() }
    }
    
    enum SearchViewStatus: Hashable {
        case normal
        case search(PaperInfo)
    }
}


extension HomeViewModel {
    public func uploadPDF(url: [URL]) -> UUID? {
        defer { self.isLoading = false }
        
        do {
            let folderID = selectedFolderID
            
            let paperInfo = try self.homeViewUseCase.uploadPDFFile(url: url, folderID: folderID)
            if let paperInfo = paperInfo {
                self.paperInfos.append(paperInfo)
                updateFilteredList()
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
        
        paperInfo.forEach {
            if $0 != nil {
                self.paperInfos.append($0!)
            }
        }
        
        return paperInfo[1]?.id
    }
    
    public func deletePDF(at id: UUID) {
        self.homeViewUseCase.deletePDF(id: id)
        self.paperInfos.removeAll(where: { $0.id == id })
    }
    
    public func duplicatePDF(at id: UUID) {
        guard let paper = self.paperInfos.first(where: { $0.id == id }) else {
            return
        }
        
        do {
            if let result = try self.homeViewUseCase.duplicatePDF(paperInfo: paper) {
                self.paperInfos.append(result)
            }
        } catch {
            if let error = error as? PDFUploadError {
                self.errorStatus = error
                self.isErrorOccured.toggle()
            }
        }
    }
    
    private func setBinding() {
        NotificationCenter.default.publisher(for: .changeHomePaperInfo)
            .sink { [weak self] noti in
                if let paper = noti.object as? PaperInfo,
                   let idx = self?.paperInfos.firstIndex(where: { $0.id == paper.id }) {
                    guard var toChangePaper = self?.paperInfos[idx] else { return }
                    
                    toChangePaper.isFavorite = paper.isFavorite
                    toChangePaper.isFigureSaved = paper.isFigureSaved
                    toChangePaper.focusURL = paper.focusURL
                    toChangePaper.title = paper.title
                    toChangePaper.tags = paper.tags
                    
                    self?.paperInfos[idx] = toChangePaper
                    
                    self?.homeViewUseCase.editPDF(toChangePaper)
                }
            }
            .store(in: &self.cancellables)
    }
}

// MARK: - EditingTitle 메소드
extension HomeViewModel {
    public func editButtonTapped(_ paperInfo: PaperInfo) {
        withAnimation(.easeInOut) {
            viewStatus = .search(paperInfo)
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
                
                PDFSharedData.shared.paperInfo?.title = title
                
                self.changedTitle = title
            case .failure(let error):
                print(error)
                self.errorStatus = .fileNameDuplication
                self.isErrorOccured.toggle()
                break
            }
        }
    }
    
    public func updateFocusURL(at id: UUID, focusURL: Data) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].focusURL = focusURL
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
}


extension HomeViewModel {
    public func uploadSampleData(focuses: [FocusAnnotation]) {
        let sampleUrl = Bundle.main.url(forResource: "engPD5", withExtension: "pdf")!
        self.paperInfos.append(PaperInfo(
            title: "A review of the global climate change impacts, adaptation, and sustainable mitigation measures",
            thumbnail: .init(),
            url: try! Data(contentsOf: sampleUrl),
            isFavorite: false,
            isFigureSaved: false,
            folderID: nil
        ))
    }
}

extension HomeViewModel {
    func selectCategory(_ category: CategorySelection) {
        switch category {
        case .main:
            isMainSelected = true
            isFavoriteSelected = false
            isTagSelected = false
            selectedFolderID = nil
            currentFolder = nil
        case .favorite:
            isMainSelected = false
            isFavoriteSelected = true
            isTagSelected = false
            selectedFolderID = nil
            currentFolder = nil
        case .tag:
            isMainSelected = false
            isFavoriteSelected = false
            isTagSelected = true
            selectedFolderID = nil
            currentFolder = nil
        case .folder(let folderID):
            isMainSelected = false
            isFavoriteSelected = false
            isTagSelected = false
            selectedFolderID = folderID
            currentFolder = folders.first { $0.id == folderID }
        }
        updateFilteredList()
    }
    
    func updateFilteredList() {
        filteredLists = paperInfos.filter { paper in
            if isMainSelected {
                return true
            } else if isFavoriteSelected {
                return paper.isFavorite
            } else if isTagSelected {
                return !paper.tags.isEmpty
            } else if let folder = currentFolder {
                return paper.folderID == folder.id
            }
            return false
        }.sorted { $0.lastModifiedDate > $1.lastModifiedDate }
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
        
        newFolderParentID = parentFolderID
        newFolderID = newFolder.id
    }
    
    public func updateFolderInfo(at id: UUID, title: String, color: String) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].title = title
            folders[index].color = color
            self.homeViewUseCase.editFolder(folders[index])
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
        if let parentID = currentFolder?.parentFolderID {
            currentFolder = folders.first { $0.id == parentID }
            selectedFolderID = parentID
        }
        updateFilteredList()
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
    public func deleteFiles(_ files: [PaperInfo]) {
        for file in files {
            self.homeViewUseCase.deletePDF(id: file.id)
            self.paperInfos.removeAll(where: { $0.id == file.id })
        }
    }
}

extension HomeViewModel {
    public func getPapaerURL(at id: UUID) -> URL? {
        var isStale: Bool = false
        
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            if let url = try? URL.init(resolvingBookmarkData: paperInfos[index].url, bookmarkDataIsStale: &isStale) {
                return url
            }
        }
        return nil
    }
    
    func getParentFolderID(for folderID: UUID) -> UUID? {
        return folders.first { $0.id == folderID }?.parentFolderID
    }
}

extension HomeViewModel {
    public func setSample() {
        let isFirst = UserDefaults.standard.bool(forKey: "sample")
        
        if isFirst {
            return
        }
        
        let url = Bundle.main.url(forResource: "sample", withExtension: "json")!
        
        let layout = try! JSONDecoder().decode(PDFLayoutResponseDTO.self, from: .init(contentsOf: url))
        
        let id = self.uploadSamplePDF()!
        UserDefaults.standard.set(id.uuidString, forKey: "sampleId")
        self.updateIsFigureSaved(at: id, isFigureSaved: true)
        
        
        
        layout.fig.forEach {
            let _ = FigureDataRepositoryImpl().saveFigureData(for: id, with: .init(
                id: $0.id,
                head: $0.head,
                coords: $0.coords))
        }
        
        UserDefaults.standard.set(true, forKey: "sample")
    }
    
    /// Deprecated
    /*
    public func resetViewModel() {
        PersistantContainer.shared.resetContainer()
        
        let fileManager = FileManager.default
        
        let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURLs = try! fileManager.contentsOfDirectory(
            at: documentURL,
            includingPropertiesForKeys: nil)
        
        fileURLs.forEach { try! fileManager.removeItem(at: $0)}
        
        pdfSharedData.paperInfo = nil
        pdfSharedData.document = nil
        self.paperInfos.removeAll()
        self.folders.removeAll()
        self.currentFolder = nil
        self.newFolderID = nil
        self.newFolderParentID = nil
        self.filteredLists.removeAll()
        self.isFavoriteSelected = false
        self.isSearching = false
        self.searchText.removeAll()
        self.recentSearches.removeAll()
        self.selectedFilter = .total
        self.selectedMenu = .main
        self.changedTitle = nil
        self.changedMemo = nil
        self.navigationStack.removeAll()
        self.isLoading = false
        self.memoText.removeAll()
        self.isErrorOccured = false
        self.errorStatus = .failedToAccessingSecurityScope
        self.isSettingMenu = false
        self.isInHomeView = false
        
        UserDefaults.standard.set(false, forKey: "sample")
        self.setSample()
    }
     */
}

enum CategorySelection: Equatable {
    case main, favorite, tag, folder(UUID)
}
