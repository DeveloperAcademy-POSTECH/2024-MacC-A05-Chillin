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
    let coords: [String]
    
    public func toDTO() -> Figure {
        .init(id: id, head: head, coords: coords)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
        hasher.combine(id)
        hasher.combine(page)
        hasher.combine(head)
        hasher.combine(coords)
        
        // CGRect를 속성별로 나눠 해싱
        hasher.combine(position.origin.x)
        hasher.combine(position.origin.y)
        hasher.combine(position.size.width)
        hasher.combine(position.size.height)
    }
    
    static func == (lhs: FigureAnnotation, rhs: FigureAnnotation) -> Bool {
        return lhs.uuid == rhs.uuid &&
        lhs.id == rhs.id &&
        lhs.page == rhs.page &&
        lhs.head == rhs.head &&
        lhs.coords == rhs.coords &&
        lhs.position.origin == rhs.position.origin &&
        lhs.position.size == rhs.position.size
    }
}

