//
//  FigureAnnotation.swift
//  Reazy
//
//  Created by 조성호 on 10/19/24.
//

import Foundation

// 이미지 위치 파악용 모델
struct FigureAnnotation: Hashable {
    let uuid: UUID
    let id: String
    let page: Int
    let id: String
    var head: String
    let position: CGRect
    
    let label: String?
    let figDesc: String?
    let coords: [String]
    let graphicCoord: [String]?
    
    public func toDTO() -> Figure {
        .init(id: id, head: head, label: label, figDesc: figDesc, coords: coords, graphicCoord: graphicCoord)
    }
}

