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
        
        if let url = try? URL.init(resolvingBookmarkData: paperInfo.url, bookmarkDataIsStale: &isStale),
           url.startAccessingSecurityScopedResource() {
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let document = PDFDocument(url: url)
            self.document = document
            self.paperInfo = paperInfo
        }
    }
}
