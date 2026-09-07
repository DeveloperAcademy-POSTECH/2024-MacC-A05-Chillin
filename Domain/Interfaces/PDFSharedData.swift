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
        // 파일을 못 찾더라도 paperInfo는 반드시 채워 둔다.
        // 예전에는 경로 해석에 실패하면 paperInfo가 nil로 남았는데, 화면은 그대로 열리기 때문에
        // 이후 paperInfo를 참조하는 코드가 크래시했다
        var resolved = paperInfo
        
        if let resolution = PaperFileLocator.resolve(paperInfo) {
            self.document = PDFDocument(url: resolution.url)
            
            if let repaired = resolution.repairedRelativePath {
                resolved.relativePath = repaired
            }
        } else {
            self.document = nil
            log("논문 파일을 찾지 못했습니다: \(paperInfo.title)")
        }
        
        if let originalPaper = self.paperInfo, originalPaper.id == paperInfo.id {
            return
        }
        self.paperInfo = resolved
    }
    
    public func updatePaperInfo() {
        NotificationCenter.default.post(name: .changeHomePaperInfo, object: self.paperInfo!)
    }
    
    public func articleId() -> String {
        self.paperInfo?.id.uuidString ?? "알 수 없음"
    }
}
