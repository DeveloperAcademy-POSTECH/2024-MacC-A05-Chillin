//
//  FocusViewModel.swift
//  Reazy
//
//  Created by 문인범 on 1/27/26.
//

import PDFKit



@Observable
final class FocusViewModel {
    public var slicedDocument: PDFDocument?
}

extension FocusViewModel {
    public func slicePDF() {
        if self.slicedDocument != nil { return }
        
        guard let document = PDFSharedData.shared.document else { return }
        
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let outputURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
        
        guard let context = CGContext(outputURL as CFURL, mediaBox: nil, nil) else {
            print("Failed to create PDF context")
            return
        }
        
        // 각 페이지 순회
        for i in 0 ..< document.pageCount {
            guard let page = document.page(at: i) else { continue }
            
            let mediaBox = page.bounds(for: .mediaBox)
            
            let halfWidth = mediaBox.width / 2
            let halfHeight = mediaBox.height
            
            var newMediaBox = CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight * 2)
            let pageInfo = [ kCGPDFContextMediaBox: Data(bytes: &newMediaBox, count: MemoryLayout<CGRect>.size) as CFData ] as CFDictionary
            
            context.beginPDFPage(pageInfo)
            
            context.saveGState()
            
            context.translateBy(x: 0, y: halfHeight)
            
            page.draw(with: .mediaBox, to: context)
            
            context.restoreGState()
            
            context.saveGState()
            
            context.translateBy(x: -halfWidth, y: 0)
            
            page.draw(with: .mediaBox, to: context)
            
            context.restoreGState()
            
            context.endPDFPage()
        }
        
        context.closePDF()
        
        self.slicedDocument = .init(url: outputURL)
    }
}
