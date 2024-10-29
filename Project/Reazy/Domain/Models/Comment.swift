//
//  Comment.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import Foundation
import PDFKit

class Comment {
    let id = UUID()
    let underLine: (page: Int, bounds: CGRect) // 텍스트 밑줄
    let coordinates: (x: CGFloat, y: CGFloat)
    let selectedText: String // 선택한 텍스트
    var text: String // 코멘트 내용
    var isPresent: Bool = false
    
    init(underLine: (page: Int, bounds: CGRect), coordinates: (x: CGFloat, y: CGFloat), text: String, selectedText: String, isPresent: Bool) {
        self.underLine = underLine
        self.coordinates = coordinates
        self.text = text
        self.selectedText = selectedText
        self.isPresent = isPresent
    }
}
