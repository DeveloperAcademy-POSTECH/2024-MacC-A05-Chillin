//
//  Comment.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import Foundation
import PDFKit

struct Comment {
    var comment: String
    var isExpanded: Bool
    let selectedText: PDFDestination
}
