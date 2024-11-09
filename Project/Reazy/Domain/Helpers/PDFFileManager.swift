//
//  FileUploadManager.swift
//  Reazy
//
//  Created by 문인범 on 11/5/24.
//

import Foundation
import PDFKit
import SwiftUICore


/**
 홈 뷰 및 pdf 업로드 관할 매니저
 */
final class PDFFileManager: ObservableObject {
    @Published public var paperInfos: [PaperInfo] = []
    @Published public var isLoading: Bool = false
    private var paperService: PaperDataService
    
    init(
        paperService: PaperDataService
    ) {
        self.paperService = paperService
        // MARK: - 기존에 저장된 데이터가 있다면 모델에 저장된 데이터를 추가
        switch paperService.loadPDFInfo() {
        case .success(let paperList):
            paperInfos = paperList.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        case .failure(_):
            return
        }
    }
}

/// pdf 업로드 관련 메소드
extension PDFFileManager {
    @MainActor
    public func uploadPDFFile(url: [URL]) throws -> UUID? {
        self.isLoading = true
        
        guard let url = url.first else { return UUID() }
        
        guard url.startAccessingSecurityScopedResource() else {
            throw PDFUploadError.failedToAccessingSecurityScope
        }
        
        defer {
            self.isLoading = false
            url.stopAccessingSecurityScopedResource()
        }
        
        let tempDoc = PDFDocument(url: url)
        var lastComponent = url.lastPathComponent.split(separator: ".")
        lastComponent.removeLast()
        
        let title = lastComponent.joined()
        
        guard let urlData = try? url.bookmarkData(options: .minimalBookmark) else {
            throw PDFUploadError.invalidURL
        }
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData
            )
            
            _ = paperService.savePDFInfo(paperInfo)
            paperInfos.append(paperInfo)
            
            return paperInfo.id
            
        } else {
            let paperInfo = PaperInfo(
                title: url.lastPathComponent,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData
            )
            
            _ = paperService.savePDFInfo(paperInfo)
            paperInfos.append(paperInfo)
            
            return paperInfo.id
        }
    }
    
    public func deletePDFFile(at id: UUID) {
        _ = paperService.deletePDFInfo(id: id)
        paperInfos.removeAll(where: { $0.id == id })
    }
    
    public func deletePDFFiles(at ids: [UUID]) {
        ids.forEach { id in
            _ = paperService.deletePDFInfo(id: id)
        }
        paperInfos.removeAll { ids.contains($0.id) }
    }
    
    public func updateTitle(at id: UUID, title: String) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].title = title
            _ = paperService.editPDFInfo(paperInfos[index])
        }
    }
    
    public func updateMemo(at id: UUID, memo: String) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].memo = memo
            _ = paperService.editPDFInfo(paperInfos[index])
        }
    }
    
    public func deleteMemo(at id: UUID) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].memo = nil
            _ = paperService.editPDFInfo(paperInfos[index])
        }
    }
    
    public func updateFavorite(at id: UUID, isFavorite: Bool) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].isFavorite = isFavorite
            _ = paperService.editPDFInfo(paperInfos[index])
        }
    }
    
    public func updateFavorites(at ids: [UUID]) {
        ids.forEach { id in
            if let index = paperInfos.firstIndex(where: { $0.id == id }) {
                paperInfos[index].isFavorite = true
                _ = paperService.editPDFInfo(paperInfos[index])
            }
        }
    }
    
    public func updateLastModifiedDate(at id: UUID, lastModifiedDate: Date) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].lastModifiedDate = lastModifiedDate
            _ = paperService.editPDFInfo(paperInfos[index])
        }
    }
}


// MARK: Sample 메소드
extension PDFFileManager {
    @MainActor
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

enum PDFUploadError: Error {
    case failedToAccessingSecurityScope
    case invalidURL
    
}
