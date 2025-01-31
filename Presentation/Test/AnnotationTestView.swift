//
//  AnnotationTestView.swift
//  Reazy
//
//  Created by 문인범 on 1/30/25.
//

import SwiftUI
import PDFKit



struct AnnotationTestView: View {
    let annotations: [PDFAnnotation] = {
        let pages = [PDFSharedData.shared.document!.page(at: 0)!, PDFSharedData.shared.document!.page(at: 1)!]
        
        var array = [PDFAnnotation]()
        
        
        pages.forEach { page in
            page.annotations.forEach {
                switch $0.markupType {
                case .highlight:
                    if let a = $0.contents {
                        if a.split(separator: "|")[0] == "UH" || a.split(separator: "|")[0] == "UC" {
                            array.append($0)
                        }
                    }
                    
                default:
                    break
                }
            }
        }
        return array
    }()
    
    @State private var texts: [String] = []
    
    
    var body: some View {
        List {
            ForEach(texts, id: \.self) { annotation in
                Text(annotation)
            }
        }
        .onAppear {
            extractTexts()
        }
    }
    
    private func extractTexts() {
        var resultText = ""
        var currentId = ""
        self.annotations.forEach { annotation in
            let id = annotation.contents!.split(separator: "|").last!
            
            if id != currentId {
                currentId = String(id)
                
                if !resultText.isEmpty {
                    self.texts.append(resultText)
                    resultText = ""
                }
            }
            
            let text = annotation.contents!.split(separator: "|")[1]
            if text == " " { return }
            
            resultText += text
        }
        
        if !resultText.isEmpty {
            self.texts.append(resultText)
        }
    }
}
