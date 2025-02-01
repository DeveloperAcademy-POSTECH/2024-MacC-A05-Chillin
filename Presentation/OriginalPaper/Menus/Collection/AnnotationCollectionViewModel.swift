//
//  AnnotationCollectionViewModel.swift
//  Reazy
//
//  Created by 문인범 on 1/31/25.
//

import Foundation
import UIKit


final class AnnotationCollectionViewModel: ObservableObject {
    @Published public var annotations: [AnnotationCollection] = []
    
    
    public func fetchData() {
        guard let document = PDFSharedData.shared.document else { return }
        let pageCount = document.pageCount
        
        var resultText = ""
        var currentId = ""
        var currentContents = ""
        
        for i in 0 ..< pageCount {
            guard let page = document.page(at: i) else { continue }
            
            page.annotations.forEach { annotation in
                switch annotation.markupType {
                case .highlight:
                    if let contents = annotation.contents {
                        if contents.split(separator: "|")[0] == "UH" || contents.split(separator: "|")[0] == "UC" {
                            let id = contents.split(separator: "|").last!
                            
                            if id != currentId {
                                if !resultText.isEmpty {
                                    extractAnnotation(
                                        contents: currentContents,
                                        body: resultText.replacingOccurrences(of: "\n", with: " ")
                                    )
                                    resultText = ""
                                }
                                
                                currentId = String(id)
                                currentContents = contents
                            }
                            
                            let text = annotation.contents!.split(separator: "|")[1]
                            if text == " " { return }
                            
                            resultText += text
                        }
                    }
                    
                default:
                    break
                }
            }
            
            if !resultText.isEmpty {
                extractAnnotation(
                    contents: currentContents,
                    body: resultText.replacingOccurrences(of: "\n", with: " ")
                )
                resultText = ""
            }
        }
    }
    
    
    
    private func extractAnnotation(contents: String, body: String) {
        let splitedContents = contents.split(separator: "|")
        
        let id = splitedContents.last!
        
        switch splitedContents[0] == "UH" {
        case true:
            guard let color = HighlightColors(rawValue: String(splitedContents[2])) else { break }
            var attributedString = AttributedString(body)
            let container = AttributeContainer([
                .backgroundColor: color.uiColor,
                .font: UIFont(name: "Pretendard-Regular", size: 12)!
            ])
            
            attributedString.setAttributes(container)
            
            let annotation = AnnotationCollection(
                id: String(id),
                annotation: .highlight,
                commenText: nil,
                contents: attributedString
            )
            
            self.annotations.append(annotation)
        case false:
            let commentText = splitedContents[2]
            
            var attributedString = AttributedString(body)
            let container = AttributeContainer([
                .font: UIFont(name: "Pretendard-Medium", size: 12)!,
                .foregroundColor: UIColor.point2,
            ])
            
            attributedString.setAttributes(container)
            
            let annotation = AnnotationCollection(
                id: String(id),
                annotation: .comment,
                commenText: String(commentText),
                contents: attributedString
            )
            
            self.annotations.append(annotation)
        }
    }
}
