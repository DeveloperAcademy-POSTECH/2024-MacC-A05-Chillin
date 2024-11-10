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
    let buttonID: String        // commentIcon
    var text: String            // 입력한 텍스트
    var selectedLine: CGRect    // selection된 라인
    var pages: [Int]            // selection page 배열
    var bounds: CGRect          // selection 전체영역
    var selectedText: String    // selection 텍스트
    var selectionsByLine: [selectionByLine]     // line별 selection 값
}

struct selectionByLine {
    var page: Int
    var bounds: CGRect
}
