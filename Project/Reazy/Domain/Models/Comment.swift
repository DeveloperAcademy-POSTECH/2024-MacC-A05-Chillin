//
//  Comment.swift
//  Reazy
//
//  Created by 김예림 on 10/24/24.
//

import Foundation
import PDFKit

struct Comment: Identifiable {
    let id : UUID
    let buttonID: String
    var selection: PDFSelection
    var text: String
    var selectedLine: CGRect
}

