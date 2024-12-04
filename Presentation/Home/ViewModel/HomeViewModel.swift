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
    
    @Published var filteredLists: [FileSystemItem] = []
    
    @Published public var isFavoriteSelected: Bool = false {
        didSet {
            resetToRoot()
            updateFilteredList()
        }
    }
    
    @Published public var isSearching: Bool = false
    @Published public var searchText: String = "" {
        didSet {
            if searchText.isEmpty {
                updateFilteredList()
            } else {
                updateSearchList(with: selectedFilter)
            }
        }
    }
    @Published public var recentSearches: [String] = UserDefaults.standard.recentSearches
    
    @Published public var selectedFilter: SearchFilter = .total
    @Published public var selectedMenu: Options = .main
    
    public var changedTitle: String?
    @Published public var changedMemo: String?
    
    // 진입 경로 추적 스택
    private var navigationStack: [(isFavoriteSelected: Bool, folder: Folder?)] = []
    
    @Published public var isLoading: Bool = false
    @Published public var memoText: String = ""
    @Published public var isErrorOccured: Bool = false
    @Published public var errorStatus: PDFUploadError = .failedToAccessingSecurityScope
    
    @Published public var isSettingMenu: Bool = false
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
                    toChangePaper.memo = paper.memo
                    toChangePaper.focusURL = paper.focusURL
                    toChangePaper.title = paper.title
                    
                    self?.paperInfos[idx] = toChangePaper
                    
                    self?.homeViewUseCase.editPDF(toChangePaper)
                }
            }
            .store(in: &self.cancellables)
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
                if isInHomeView {
                    paperInfos[index].title = title
                }
                
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
    
    func updateSearchList(with filter: SearchFilter) {
        let items = sortLists(paperInfos: paperInfos, folders: folders)
        
        let lowercasedSearchText = searchText.lowercased()
        
        if filter == .total {
            filteredLists = items.filter( { $0.title.lowercased().contains(lowercasedSearchText) })
        } else if filter == .paper {
            filteredLists = items.filter { item in
                if case .paper = item {
                    return item.title.lowercased().contains(lowercasedSearchText)
                }
                return false
            }
        } else if filter == .folder {
            filteredLists = items.filter { item in
                if case .folder = item {
                    return item.title.lowercased().contains(lowercasedSearchText)
                }
                return false
            }
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
    
    public func updateFolderMemo(at id: UUID, memo: String?) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].memo = memo
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
    public func addSearchTerm(_ term: String) {
        var searches = UserDefaults.standard.recentSearches
        
        // 중복 제거: 기존 검색어 목록에서 제거
        if let index = searches.firstIndex(of: term) {
            searches.remove(at: index)
        }
        
        // 배열이 10개를 초과하면 가장 오래된 항목 제거
        if searches.count == 10 {
            searches.removeLast()
        }
        
        searches.insert(term, at: 0)
        UserDefaults.standard.recentSearches = searches
    }

    public func clearAllSearchTerms() {
        UserDefaults.standard.recentSearches = []
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
}

enum SearchFilter: CaseIterable {
    case total
    case paper
    case folder
    
    var title: String {
        switch self {
        case .total:
            return "전체"
        case .paper:
            return "논문"
        case .folder:
            return "폴더"
        }
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
}
