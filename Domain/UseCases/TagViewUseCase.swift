//
//  TagViewUseCase.swift
//  Reazy
//
//  Created by 김예림 on 2/17/25.
//

import Foundation

typealias TagViewWithIOUseCase = TagViewUseCase & HomeSearchUseCase

protocol TagViewUseCase {
    func deleteTag(id: UUID) -> Bool
    func createTag(name: String) throws -> Tag
    func fetchTags() -> [Tag]
    func fetchFilteredPaperList(tags: [Tag]) -> [PaperInfo]
}

final class DefaultTagViewUseCase: TagViewUseCase {
    private let tagDataRepository: TagDataRepository
    private let paperDataRepository: PaperDataRepository
    
    init(
        tagRepository: TagDataRepository,
        paperDataRepository: PaperDataRepository
    ) {
        self.tagDataRepository = tagRepository
        self.paperDataRepository = paperDataRepository
    }
    
    func deleteTag(id: UUID) -> Bool {
        switch tagDataRepository.deleteTag(tagID: id) {
        case .success(_):
            return true
        case .failure(_):
            return false
        }
    }
    
    func createTag(name: String) throws -> Tag {
        switch tagDataRepository.addTag(name: name) {
        case let .success(tag):
            return tag
        case .failure(_):
            throw NSError()
        }
    }
    
    func fetchTags() -> [Tag] {
        switch tagDataRepository.fetchAllTags() {
        case let .success(tags):
            return tags
        case .failure(_):
            return []
        }
    }
    
    func fetchFilteredPaperList(tags: [Tag]) -> [PaperInfo] {
        if tags.isEmpty { return [] }
        var result = Set<PaperInfo>()
        
        tags.forEach {
            if case let .success(paperInfos) = tagDataRepository.fetchPapersByTag(tagID: $0.id) {
                paperInfos.forEach { result.insert($0) }
            }
        }
        
        return Array(result)
    }
}


extension DefaultTagViewUseCase: HomeSearchUseCase {
    func fetchSearchList(target: SearchTarget, matches: String) -> Result<[PaperInfo], any Error> {
        return .failure(NSError())
    }
    
    func fetchByTagId(tagId: UUID) -> Result<[PaperInfo], any Error> {
        return .failure(NSError())
    }
    
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        paperDataRepository.editPDFInfo(info)
    }
    
    func deletePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.deletePDFInfo(id: info.id)
    }
    
    func duplicatePDF(_ info: PaperInfo) -> Result<PaperInfo, any Error> {
        var isStale = false
        
        do {
            let originalUrl = try URL.init(resolvingBookmarkData: info.url, bookmarkDataIsStale: &isStale)
            
            if let (data, url) = try self.savePDFIntoDirectory(url: originalUrl, isSample: false) {
                
                let newPaperInfo = PaperInfo(
                    title: url.deletingPathExtension().lastPathComponent,
                    thumbnail: info.thumbnail,
                    url: data,
                    focusURL: info.focusURL,
                    lastModifiedDate: Date(),
                    isFavorite: info.isFavorite,
                    isFigureSaved: info.isFigureSaved,
                    folderID: info.folderID)
                
                self.paperDataRepository.duplicatePDFInfo(id: info.id, info: newPaperInfo)
                return .success(newPaperInfo)
            }
            
            return .failure(PDFUploadError.fileNameDuplication)
        } catch {
            return .failure(PDFUploadError.fileNameDuplication)
        }
    }
    
    
}


extension DefaultTagViewUseCase {
    internal func savePDFIntoDirectory(url: URL, isSample: Bool) throws -> (Data, URL)? {
        do {
            let manager = FileManager.default
            let documentURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentURL.appending(path: url.lastPathComponent)
                        
            let _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            var error: NSError?
            
            // 업로드 전 로컬에 다운로드 진행
            NSFileCoordinator().coordinate(readingItemAt: url, options: .forUploading, error: &error) { _ in
//                print("coordinated URL: \(cloudURL)")
            }
            
            if let _ = try? Data(contentsOf: fileURL) {
                var dupNum = 1
                
                
                var lastComponent = url.lastPathComponent.split(separator: ".")
                lastComponent.removeLast()
                
                
                while dupNum < 100 {
                    let tempURL = documentURL.appending(path: lastComponent.joined() + "(\(dupNum)).pdf")
                    
                    guard let _ = try? Data(contentsOf: tempURL) else {
                        try manager.copyItem(at: url, to: tempURL)
                        return try (tempURL.bookmarkData(options: .minimalBookmark), tempURL)
                    }
                    
                    if dupNum == 99 {
                        throw PDFUploadError.fileNameDuplication
                    }
                    
                    dupNum += 1
                }
                
                
            } else {
                try manager.copyItem(at: url, to: fileURL)
            }
            
            let urlData = try fileURL.bookmarkData(options: .minimalBookmark)
            
            return (urlData, fileURL)
        } catch {
            print("error copying file: \(error)")
        }
        
        return nil
    }
}
