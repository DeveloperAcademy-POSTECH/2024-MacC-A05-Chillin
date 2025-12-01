//
//  HomeSearchUseCase.swift
//  Reazy
//
//  Created by 문인범 on 2/13/25.
//

import Foundation
import RegexBuilder


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
            
            if let (data, url) = self.copyItem(url: originalUrl) {
                
                let newPaperInfo = PaperInfo(
                    title: url.deletingPathExtension().lastPathComponent,
                    thumbnail: info.thumbnail,
                    url: data,
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



extension DefaultHomeSearchUseCase {
    private func fetchPapersByTagName(_ tagName: String) -> [PaperInfo] {
        let response = tagDataRepository.fetchAllTags()
        if case let .success(tags) = response {
            let result = tags.filter { $0.name.localizedCaseInsensitiveContains(tagName) }
            
            if result.isEmpty {
                return []
            }
            
            let paperTagResponse = tagDataRepository.fetchPapersByTag(tagID: result.first!.id)
            guard case let .success(papers) = paperTagResponse else { return [] }
            
            return papers
        }
        return []
    }
    
    internal func copyItem(url: URL) -> (Data, URL)? {
        do {
            let manager = FileManager.default
            let documentURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
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
            print("error copying file: \(error)")
        }
        
        return nil
    }
}


