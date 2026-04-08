//
//  HomeViewModel.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation
import SwiftUI
import Combine


class HomeViewModel: ObservableObject {
    private let pdfSharedData: PDFSharedData = .shared
    
    // MARK: - Home 상태 관리
    /// 홈 뷰 상태 관리 변수
    @Published public var homeViewStatus: HomeViewStatus = .main {
        didSet {
            if case let .folder(folderID) = homeViewStatus {
                currentFolder = folders.first { $0.id == folderID }
            } else {
                currentFolder = nil
            }
            updateFilteredList()
        }
    }
    
    /// 홈 뷰 Alert 관리 변수
    @Published public var homeViewAction: HomeViewAction = .none {
        didSet {
            self.previousAction = oldValue
        }
    }
    public var previousAction: HomeViewAction?

    
    
    // MARK: - HomeView 프로퍼티
    @Published public var filteredLists: [PaperInfo] = []  // HomeView, PaperListView
    @Published public var selectedItems: Set<UUID> = []    // HomeSearchView, HomeView, PaperListView, TagView
    @Published public var isLoading: Bool = false   // TagControlView, HomeSearchView, HomeView, SearchView
    

    
    public var selectedItemID: UUID?    // HomeView
    public var itemsToMove: [PaperInfo] {   // HomeView
        self.selectedItems.isEmpty
        ? (self.selectedItemID.flatMap { id in
            self.filteredLists.first(where: { $0.id == id })
        }).map { [$0] } ?? []
        : self.selectedItems.compactMap { id in
            self.filteredLists.first(where: { $0.id == id })
        }
    }
    
    public var isAtRoot: Bool { // HomeView
        currentFolder == nil && homeViewStatus.currentFolderID == nil
    }
    
    public func handleDrop(to folderId: UUID, droppedItem: PaperInfo) { // HomeListView
        DispatchQueue.main.async {
            self.updatePaperLocation(at: droppedItem.id, folderID: folderId)
        }
    }
    
    // MARK: - 폴더 상태 관리
    // 전체 폴더 배열
    @Published public var folders: [Folder] = [] {  // HomeView, MainPDFView
        didSet {
            updateFilteredList()
        }
    }
    @Published public var folderCreationPosition: FolderCreationPosition = .intoCurrent // HomeView, HomeFolderPopoverView, HomeListView
    @Published public var expandedFolders: Set<UUID> = []   // MoveFolderView, HomeListView
    @Published public var expandedMoveFolders: Set<UUID> = []  // MoveFolderView
    
    // 폴더 이동 화면에서 새 폴더 생성했을 경우 Focus하기 위한 변수
    @Published public var newFolderParentID: UUID?  // MoveFolderView
    @Published public var newFolderID: UUID?    // MoveFolderView
    @Published public var currentFolder: Folder? = nil {    // PaperListView, HomeListView
        didSet {
            updateFilteredList()
        }
    }
    
    public var rootFolders: [Folder] {  // MoveFolderView, HomeListView
        self.folders.filter { $0.parentFolderID == nil }
    }
    
    
    // MARK: - Oreintation 관련 변수
    public func updatePortrait() {  // PaperListView
        if UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown {
            self.isPortrait = true
        }
    }
    public var isPortrait: Bool = false // HomeSearchView, PaperListView, TagView, SearchView
    
    // HomeViewModel, TagViewModel
    private let orientationPublisher = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
    
    // MARK: - 나머지
    private let homeViewUseCase: HomeViewUseCase
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var paperInfos: [PaperInfo] = [] {
        didSet {
            updateFilteredList()
        }
    }
    
    init(homeViewUseCase: HomeViewUseCase) {
        self.homeViewUseCase = homeViewUseCase
        
        switch homeViewUseCase.loadPDFs() {
        case .success(let paperInfos):
            self.paperInfos = paperInfos
        case .failure(let error):
            log(error)
            return
        }
        
        self.fetchFolders()
        
        updateFilteredList()
        setBinding()
    }
    
    deinit {
        self.cancellables.forEach { $0.cancel() }
    }
}

// MARK: - 초기 세팅
extension HomeViewModel {
    private func setBinding() {
        self.orientationPublisher
            .sink { _ in
                let currentOrientation = UIDevice.current.orientation
                
                switch currentOrientation {
                case .portrait, .portraitUpsideDown:
                    self.isPortrait = true
                case .landscapeLeft, .landscapeRight:
                    self.isPortrait = false
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}


// MARK: - PaperInfo CRUD 메소드
extension HomeViewModel {
    public func fetchPaperList() {
        self.paperInfos = (try? homeViewUseCase.loadPDFs().get()) ?? []
    }
    public func uploadPDF(url: [URL]) -> UUID? {
        defer { self.isLoading = false }
        
        do {
            let folderID = homeViewStatus.currentFolderID
            let paperInfo = try self.homeViewUseCase.uploadPDFFile(url: url, folderID: folderID)
            if let paperInfo = paperInfo {
                self.paperInfos.append(paperInfo)
                updateFilteredList()
            }
            return paperInfo?.id
        } catch {
            log(error)
            return nil
        }
    }
    
    public func deletePDF(at id: UUID) {
        self.homeViewUseCase.deletePDF(id: id)
        self.paperInfos.removeAll(where: { $0.id == id })
    }
    
    public func deleteFiles(_ files: [PaperInfo]) {
        for file in files {
            self.homeViewUseCase.deletePDF(id: file.id)
            self.paperInfos.removeAll(where: { $0.id == file.id })
        }
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
            log(error)
        }
    }
    
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
            selectedItems.removeAll()
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
    
    public func updateTitle(at id: UUID, title: String, completion: @escaping (Bool) -> Void) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            var changablePaper = paperInfos[index]
            changablePaper.title = title
            let result = self.homeViewUseCase.editPDF(changablePaper)
            
            switch result {
            case .success:
                paperInfos[index].title = title
                
                PDFSharedData.shared.paperInfo?.title = title
                
                completion(true)
            case .failure(let error):
                log(error)
                completion(false)
            }
        }
    }
    
    public func updateFocusURL(at id: UUID, focusURL: Data) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].focusURL = focusURL
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    // MARK: - Sample 업로드 메소드
    public func uploadSamplePDF() -> UUID? {
        let paperInfo = self.homeViewUseCase.uploadSamplePDFFile()
        
        fetchPaperList()
        fetchFolders()
        
        return paperInfo[1]?.id
    }
    
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
    
    public func setSample() {
        if UserDefaults.standard.bool(forKey: "sample") {
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
}

// MARK: - 버튼 액션 메소드
extension HomeViewModel {
    public func checkPaperButtonTapped(paperInfo: PaperInfo) {
        switch self.selectedItems.contains(paperInfo.id) {
        case true:
            self.selectedItems.remove(paperInfo.id)
        case false:
            self.selectedItems.insert(paperInfo.id)
        }
    }
    
    public func editButtonTapped(_ paperInfo: PaperInfo) {
        withAnimation(.easeInOut) {
            homeViewAction = .editingPaperTitle(paperInfo)
        }
    }
    
    public func categoryButtonTapped(_ status: HomeViewStatus) {
        self.homeViewStatus = status
        updateFilteredList()
    }
}


// MARK: - 폴더 관련 메소드
extension HomeViewModel {
    private func fetchFolders() {
        switch self.homeViewUseCase.loadFolders() {
        case let .success(folders):
            self.folders = folders
        case let .failure(error):
            log(error)
        }
    }
    
    public func depth(of folderID: UUID?) -> Int {
        guard let folderID = folderID,
              let folder = folders.first(where: { $0.id == folderID }) else {
            return 0
        }
        
        var currentFolder = folder
        var depth = 1

        while let parentID = currentFolder.parentFolderID,
              let parent = folders.first(where: { $0.id == parentID }) {
            currentFolder = parent
            depth += 1
        }

        return depth
    }
    
    public func totalDepthInBranch(for folderID: UUID?) -> Int {
        return depthAbove(folderID: folderID) + 1 + depthBelow(folderID: folderID)
    }
    
    public func createFolder(to parentFolderID: UUID?, title: String, color: String) -> Folder {
        let folder = Folder(
            id: UUID(),
            title: title,
            color: color,
            parentFolderID: parentFolderID
        )
        
        return folder
    }
    
    public func createSubfolder(in folderId: UUID?, title: String, color: String) {
        let newFolder = saveFolder(to: folderId, title: title, color: color)
        
        newFolderID = newFolder.id
        newFolderParentID = folderId
        
        let parentIDs = collectParentFolderIDs(from: newFolder)
        expandedFolders.formUnion(parentIDs)
    }
    
    public func createSubfolderInSelectedFolder(title: String, color: String) {
        let folder = selectedFolder()
        createSubfolder(in: folder?.id, title: title, color: color)
    }

    public func createFolderAboveSelectedFolder(title: String, color: String) {
        let folder = selectedFolder()
        createFolderAbove(folder, title: title, color: color)
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
        let folderIDsToDelete = collectFolderAndDescendants(from: id)

        let fileIDsToDelete: [UUID] = paperInfos
            .filter { file in
                guard let folderID = file.folderID else { return false }
                return folderIDsToDelete.contains(folderID)
            }
            .map { $0.id }


        for fileID in fileIDsToDelete {
            homeViewUseCase.deletePDF(id: fileID)
        }

        for folderID in folderIDsToDelete {
            homeViewUseCase.deleteFolder(id: folderID)
        }

        paperInfos.removeAll { fileIDsToDelete.contains($0.id) }
        folders.removeAll { folderIDsToDelete.contains($0.id) }
        homeViewAction = .deletingFolderAlert
    }
    
    public func navigateToParent() {
        if let parentID = currentFolder?.parentFolderID {
            currentFolder = folders.first { $0.id == parentID }
            homeViewStatus = .folder(parentID)
        }
        updateFilteredList()
    }
    
    public func childFolders(of folderID: UUID?) -> [Folder] {  // MoveFolderView, HomeListView
        self.folders.filter { $0.parentFolderID == folderID }
    }
    
    public func hasChildren(folder: Folder) -> Bool {   // MoveFolderView, HomeListView
        !childFolders(of: folder.id).isEmpty
    }
    
    public func toggleExpansionMoveFolders(folder: Folder) {   // MoveFolderView, HomeListView
        if self.expandedMoveFolders.contains(folder.id) {
            self.expandedMoveFolders.remove(folder.id)
        } else {
            self.expandedMoveFolders.insert(folder.id)
        }
    }
    
    public func expandOnlyParentFolders(of folderID: UUID) {    // MoveFolderView
        if let parentID = self.getParentFolderID(for: folderID) {
            self.expandedMoveFolders.insert(parentID)
            expandOnlyParentFolders(of: parentID)
        }
    }
    
    public func toggleExpansionFolder(folder: Folder) {
        if self.expandedFolders.contains(folder.id) {
            self.expandedFolders.remove(folder.id)
        } else {
            self.expandedFolders.insert(folder.id)
        }
    }
    
    private func depthAbove(folderID: UUID?) -> Int {
        guard let folderID = folderID,
              let folder = folders.first(where: { $0.id == folderID }) else { return 0 }

        var current = folder
        var depth = 0

        while let parentID = current.parentFolderID,
              let parent = folders.first(where: { $0.id == parentID }) {
            current = parent
            depth += 1
        }

        return depth
    }
    
    private func depthBelow(folderID: UUID?) -> Int {
        guard let folderID = folderID else { return 0 }

        let children = folders.filter { $0.parentFolderID == folderID }

        if children.isEmpty {
            return 0
        }

        let childDepths = children.map { depthBelow(folderID: $0.id) }
        return 1 + (childDepths.max() ?? 0)
    }
    
    private func selectedFolder() -> Folder? {
        guard let selectedID = homeViewStatus.currentFolderID else { return nil }
        return folders.first(where: { $0.id == selectedID })
    }
    
    private func collectParentFolderIDs(from folder: Folder?) -> [UUID] {
        var result: [UUID] = []
        var currentFolder = folder

        while let parentID = currentFolder?.parentFolderID,
              let parentFolder = folders.first(where: { $0.id == parentID }) {
            result.append(parentID)
            currentFolder = parentFolder
        }

        return result
    }
    
    private func saveFolder(to parentFolderID: UUID?, title: String, color: String) -> Folder {
        let newFolder = self.createFolder(to: parentFolderID, title: title, color: color)
        
        self.homeViewUseCase.saveFolder(newFolder)
        folders.append(newFolder)
        
        return newFolder
    }
    
    private func createFolderAbove(_ folder: Folder?, title: String, color: String) {
        guard let folder = folder else { return }

        let newParent = saveFolder(to: folder.parentFolderID, title: title, color: color)
        
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            folders[index].parentFolderID = newParent.id
            homeViewUseCase.editFolder(folders[index])
        }

        newFolderID = newParent.id
        newFolderParentID = newParent.parentFolderID
        
        let parentIDs = collectParentFolderIDs(from: newParent)
        expandedFolders.formUnion(parentIDs)
    }
    
    private func collectFolderAndDescendants(from parentID: UUID) -> [UUID] {
        var result: [UUID] = [parentID]

        let childFolders = folders.filter { $0.parentFolderID == parentID }

        for child in childFolders {
            result.append(contentsOf: collectFolderAndDescendants(from: child.id))
        }

        return result
    }
    
    private func getParentFolderID(for folderID: UUID) -> UUID? {
        return folders.first { $0.id == folderID }?.parentFolderID
    }
}

// MARK: - 그 외 나머지
extension HomeViewModel {
    public func navigateToPaper(_ id: UUID) {
        guard let selectedPaper = self.paperInfos.first(where: { $0.id == id }) else {
            return
        }
        
        var isStale = false
        let data = selectedPaper.url
        
        guard let url = try? URL.init(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
            log("bookmarkdata to url failed")
            return
        }
        
        if isStale {
            log("Bookmark(\(url.lastPathComponent)) is stale")
            guard let newURL = try? url.bookmarkData(options: .suitableForBookmarkFile) else {
                log("Unable to create bookmark")
                return
            }
            
            let idx = self.paperInfos.firstIndex { $0.id == id }!
            self.paperInfos[idx].url = newURL
        }
        
        NavigationCoordinator.shared.push(.mainPDF(paperInfo: selectedPaper))
    }
    
    private func updateFilteredList() {
        filteredLists = paperInfos.filter { paper in
            switch self.homeViewStatus {
            case .main, .edit:
                return true
            case .favorite:
                return paper.isFavorite
            case .tag:
                return !paper.tags.isEmpty
            case let .folder(id):
                return paper.folderID == id
            default:
                return true
            }
        }.sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }
}

enum FolderCreationPosition {
    case intoCurrent
    case aboveCurrent
}
