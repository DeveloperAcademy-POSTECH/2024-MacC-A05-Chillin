//
//  Tag.swift
//  Reazy
//
//  Created by 유지수 on 2/9/25.
//

import Foundation
import CoreTransferable

struct Tag: DynamicCell, Codable, Transferable {
    
    let id: UUID
    var name: String
    var isSelected: Bool
    
    init(id: UUID = .init(), name: String, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
    }
    
    func getCellWidth() -> CGFloat {
        let count = self.name.count
        return CGFloat(10 + count * 11)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}
