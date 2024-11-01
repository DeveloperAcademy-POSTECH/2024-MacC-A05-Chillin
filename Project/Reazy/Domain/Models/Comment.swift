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
    var coordinates: CGPoint = .zero
    var text: String = "" // 코멘트 내용
    var isPresent: Bool = false
    
    init(text: String, isPresent: Bool) {
        self.text = text
        self.isPresent = isPresent
    }
}
