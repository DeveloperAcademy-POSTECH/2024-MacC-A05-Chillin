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
    let coordinates: (x: CGFloat, y: CGFloat)
    var text: String = ""// 코멘트 내용
    var isPresent: Bool = false
    
    init(coordinates: (x: CGFloat, y: CGFloat), text: String, isPresent: Bool) {
        self.coordinates = coordinates
        self.text = text
        self.isPresent = isPresent
    }
}
