//
//  FileUploadManager.swift
//  Reazy
//
//  Created by 문인범 on 11/5/24.
//

import Foundation
import PDFKit


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
            paperInfos = paperList
        case .failure(_):
            return
        }
    }
}

/// pdf 업로드 관련 메소드
extension PDFFileManager {
    @MainActor
    public func uploadPDFFile(url: [URL]) async throws {
        self.isLoading = true
        
        guard let url = url.first else { return }
        
        guard url.startAccessingSecurityScopedResource() else {
            throw PDFUploadError.failedToAccessingSecurityScope
        }
        
        defer {
            self.isLoading = false
            url.stopAccessingSecurityScopedResource()
        }
        
        
        let result: PDFInfo = try await NetworkManager.fetchPDFExtraction(process: .processHeaderDocument, pdfURL: url)
        
        let names = result.names?.reduce("") { $0 + $1 + "," } ?? "알 수 없음"
        
        let tempDoc = PDFDocument(url: url)
        
        let pageCount = tempDoc?.pageCount
        
        guard let urlData = try? url.bookmarkData(options: .minimalBookmark) else {
            throw PDFUploadError.invalidURL
        }
        
        //TODO: 데이터 저장 메소드 추가 필요
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            // TODO: - `paperService.savePDFInfo(paperInfo)` 코드 추가
            /// 삭제도 삭제 로직이 들어가는 곳에 함수를 추가하면 됩니다!
            paperInfos.append(.init(
                title: result.title ?? url.lastPathComponent,
                datetime: result.date?.date ?? "알 수 없음",
                author: names,
                year: result.date?.date ?? "알 수 없음",
                pages: pageCount ?? 0,
                publisher: "알 수 없음",
                thumbnail: thumbnailData!,
                url: urlData)
            )
        } else {
            paperInfos.append(.init(
                title: result.title ?? url.lastPathComponent,
                datetime: result.date?.date ?? "알 수 없음",
                author: names,
                year: result.date?.date ?? "알 수 없음",
                pages: pageCount ?? 0,
                publisher: "알 수 없음",
                thumbnail: .init(),
                url: urlData)
            )
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
            datetime: "2024. 10. 20. 오후 08:56",
            author: "Smith, John",
            year: "2010",
            pages: 43,
            publisher: "NATURE",
            thumbnail: .init(),
            url: try! Data(contentsOf: sampleUrl),
            isFavorite: false
        ))
    }
}

enum PDFUploadError: Error {
    case failedToAccessingSecurityScope
    case invalidURL
    
}
