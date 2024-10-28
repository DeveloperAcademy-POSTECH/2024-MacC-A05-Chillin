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
    var coordinates: (x: CGFloat, y: CGFloat)
    var text: String
    var isSelected: Bool = false
    
    init(coordinates: (x: CGFloat, y: CGFloat), text: String, isSelected: Bool) {
        self.coordinates = coordinates
        self.text = text
        self.isSelected = isSelected
    }
}
