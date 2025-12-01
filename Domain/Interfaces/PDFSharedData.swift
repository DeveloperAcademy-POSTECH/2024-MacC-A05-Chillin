//
//  PDFSharedData.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import PDFKit


/**
 PDF 의존성 주입 클래스
 */
class PDFSharedData {
    static let shared = PDFSharedData()
    
    public var document: PDFDocument?
    public var paperInfo: PaperInfo?
    
    private init() { }
    
    public func makeDocument(from paperInfo: PaperInfo) {
        var isStale: Bool = false
        
        do {
            let url = try URL(resolvingBookmarkData: paperInfo.url, bookmarkDataIsStale: &isStale)
            let document = PDFDocument(url: url)
            self.document = document
            
            if let originalPaper = self.paperInfo, originalPaper.id == paperInfo.id {
                return
            }
            self.paperInfo = paperInfo
            
        } catch {
            print("Failed to make Document \(#function)")
        }
    }
    
    public func updatePaperInfo() {
        NotificationCenter.default.post(name: .changeHomePaperInfo, object: self.paperInfo!)
    }
    
    public func articleId() -> String {
        self.paperInfo?.id.uuidString ?? "알 수 없음"
    }
}
