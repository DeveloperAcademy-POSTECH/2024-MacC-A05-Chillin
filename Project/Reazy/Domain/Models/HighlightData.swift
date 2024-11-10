//
//  HighlightData.swift
//  Reazy
//
//  Created by  Lucid on 11/8/24.
//

import UIKit
import PDFKit

// MARK: - [Lucid] 하이라이트 데이터 구조 선언
struct Highlight {
    let id: UUID                // 하이라이트 고유 ID
    let pageIndex: PDFPage      // 하이라이트 해당 페이지
    let bounds: CGRect          // 하이라이트 영역 좌표
    let color: UIColor          // 하이라이트 색상
}
