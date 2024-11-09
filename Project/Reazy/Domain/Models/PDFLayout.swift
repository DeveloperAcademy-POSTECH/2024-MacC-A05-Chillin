//
//  PDFInfo.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation


/**
 Grobid 모델에서 PDF 분석 결과를 받아오는 구조체
 */
struct PDFLayout: Codable {
    let fig: [Figure]
    let table: [Figure]?
    
    struct Figure: Codable {
        let id: String
        let head: String?
        let label: String?
        let figDesc: String?
        let coords: [String]
        let graphicCoord: [String]?
    }
}
