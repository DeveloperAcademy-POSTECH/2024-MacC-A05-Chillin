//
//  HomeSearchUseCase.swift
//  Reazy
//
//  Created by 문인범 on 2/13/25.
//

import Foundation


protocol HomeSearchUseCase: Sendable {
    func fetchSearchList(target: SearchTarget, matches: String) -> Result<[PaperInfo], any Error>
    func fetchByTagId(tagId: UUID) -> Result<[PaperInfo], any Error>
    
    @discardableResult
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deletePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func duplicatePDF(_ info: PaperInfo) -> Result<PaperInfo, any Error>
}

enum SearchTarget {
    case title
    case tag
}

final class DefaultHomeSearchUseCase: HomeSearchUseCase {
    private let paperDataRepository: PaperDataRepository
    private let tagDataRepository: TagDataRepository
    
    init(paperDataRepository: PaperDataRepository, tagDataRepository: TagDataRepository) {
        self.paperDataRepository = paperDataRepository
        self.tagDataRepository = tagDataRepository
    }
    
    func fetchSearchList(target: SearchTarget, matches: String) -> Result<[PaperInfo], any Error> {
        switch target {
        case .title:
            let response = paperDataRepository.loadPDFInfo()
            if case let .success(papers) = response {
                let result = papers.filter { $0.title.localizedStandardContains(matches) }
                return .success(result)
            } else {
                return .failure(NSError())
            }
        case .tag:
            let papers = fetchPapersByTagName(matches)
            return .success(papers)
        }
    }
    
    func fetchByTagId(tagId: UUID) -> Result<[PaperInfo], any Error> {
        let response = tagDataRepository.fetchPapersByTag(tagID: tagId)
        if case let .success(papers) = response {
            return .success(papers)
        }
        return .failure(NSError())
    }
    
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.editPDFInfo(info)
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



extension DefaultHomeSearchUseCase {
    private func fetchPapersByTagName(_ tagName: String) -> [PaperInfo] {
        let response = tagDataRepository.fetchAllTags()
        if case let .success(tags) = response {
            let result = tags.filter { $0.name == tagName }
            
            if result.isEmpty {
                return []
            }
            
            let paperTagResponse = tagDataRepository.fetchPapersByTag(tagID: result.first!.id)
            guard case let .success(papers) = paperTagResponse else { return [] }
            
            return papers
        }
        return []
    }
    
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


