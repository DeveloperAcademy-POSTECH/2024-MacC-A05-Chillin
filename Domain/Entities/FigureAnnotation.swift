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
    var head: String
    let position: CGRect
    
    let label: String?
    let figDesc: String?
    let coords: [String]
    let graphicCoord: [String]?
    
    public func toFigureDTO() -> Figure {
        .init(id: id, head: head, label: label, figDesc: figDesc, coords: coords, graphicCoord: graphicCoord)
    }
    
    public func toCollectionDTO() -> Collection {
        .init(id: id, head: head, label: label, figDesc: figDesc, coords: coords, graphicCoord: graphicCoord)
    }
}

