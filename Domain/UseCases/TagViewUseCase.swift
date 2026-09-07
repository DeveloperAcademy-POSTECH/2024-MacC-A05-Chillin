//
//  TagViewUseCase.swift
//  Reazy
//
//  Created by 김예림 on 2/17/25.
//

import Foundation
import RegexBuilder

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
            try? tagDataRepository.saveContext()
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
                var isTagContained = true
                paperInfos.forEach { paperInfo in
                    for tag in tags {
                        if !paperInfo.tags.contains(tag) {
                            isTagContained = false
                            break
                        }
                    }
                    
                    if isTagContained { result.insert(paperInfo) }
                }
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
        do {
            guard let originalUrl = PaperFileLocator.resolve(info)?.url else {
                throw PDFUploadError.fileNameDuplication
            }
            
            if let (data, url) = self.copyItem(url: originalUrl) {
                
                let newPaperInfo = PaperInfo(
                    title: url.deletingPathExtension().lastPathComponent,
                    thumbnail: info.thumbnail,
                    url: data,
                    relativePath: PaperFileLocator.storageRelativePath(of: url),
                    focusURL: info.focusURL,
                    lastModifiedDate: Date(),
                    isFavorite: false,
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
    internal func copyItem(url: URL) -> (Data, URL)? {
        do {
            let manager = FileManager.default
            let documentURL = manager.pdfStorageDirectory
            let fileURL = documentURL.appending(path: url.lastPathComponent)
            
            var error: NSError?
            
            // 업로드 전 로컬에 다운로드 진행
            NSFileCoordinator().coordinate(readingItemAt: url, options: .forUploading, error: &error) { _ in
//                print("coordinated URL: \(cloudURL)")
            }
            
            let lastComponent = url.deletingPathExtension().lastPathComponent
            var splitComp = lastComponent.split(separator: " ")
            
            let regex = Regex {
                "("
                OneOrMore(.digit)
                ")"
            }
            
            if let splitCompLast = splitComp.last?.prefixMatch(of: regex) {
                var fileNumString = splitCompLast.output
                fileNumString.removeFirst()
                fileNumString.removeLast()
                
                splitComp.removeLast()
                let fileName = splitComp.joined(separator: " ")
                
                var fileNum = Int(fileNumString)!
                
                while(fileNum < 9999) {
                    let resultURL = documentURL.appending(path: fileName + " (\(fileNum+1)).pdf")
                    
                    if let _ = try? Data(contentsOf: resultURL) {
                        fileNum += 1
                        continue
                    }
                    
                    try manager.copyItem(at: url, to: resultURL)
                    let bookmarkData = try resultURL.bookmarkData(options: .suitableForBookmarkFile)
                    return (bookmarkData, resultURL)
                }
            } else {
                var num = 1
                while(num < 9999) {
                    let resultURL = documentURL.appending(path: lastComponent + " (\(num)).pdf")
                    
                    if let _ = try? Data(contentsOf: resultURL) {
                        num += 1
                        continue
                    }
                    
                    try manager.copyItem(at: fileURL, to: resultURL)
                    let urlData = try resultURL.bookmarkData(options: .suitableForBookmarkFile)
                    
                    return (urlData, resultURL)
                }
            }
        } catch {
            log("error copying file: \(error)")
        }
        
        return nil
    }
}
