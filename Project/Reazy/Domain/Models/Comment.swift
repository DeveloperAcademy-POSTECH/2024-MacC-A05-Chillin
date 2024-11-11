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
    let buttonId: UUID                          // commentIcon
    var text: String                            // 입력한 텍스트
    var selectedText: String                    // selection 텍스트
    var selectionsByLine: [selectionByLine]     // 하이라이트
    var pages: [Int]                            // selection page 배열
    var bounds: CGRect                          // selection 전체영역
}

struct selectionByLine {
    var page: Int
    var bounds: CGRect
}

struct ButtonGroup: Identifiable {
    let id : UUID
    var page: Int
    var selectedLine: CGRect
    var buttonPosition: CGRect
}
