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
    
    init(id: UUID = .init(), name: String) {
        self.id = id
        self.name = name
    }
    
    func getCellWidth() -> CGFloat {
        let count = self.name.count
        return CGFloat(10 + count * 10)
    }
}
