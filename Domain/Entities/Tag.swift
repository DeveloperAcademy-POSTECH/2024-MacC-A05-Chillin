//
//  Tag.swift
//  Reazy
//
//  Created by 유지수 on 2/9/25.
//

import Foundation

struct Tag: DynamicCell {
    let id: UUID
    var name: String
    var isSeleted: Bool
    
    init(id: UUID = .init(), name: String, isSeleted: Bool = false) {
        self.id = id
        self.name = name
        self.isSeleted = isSeleted
    }
    
    func getCellWidth() -> CGFloat {
        let count = self.name.count
        return CGFloat(10 + count * 10)
    }
}
