//
//  Tag.swift
//  Reazy
//
//  Created by 유지수 on 2/9/25.
//

import Foundation
import CoreTransferable
import SwiftUI

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
        var totalWidth: CGFloat = 0

        for char in name {
            if char.isHangul {
                totalWidth += 13
            } else if char.isEnglish {
                totalWidth += 8
            } else {
                totalWidth += 10 //기타
            }
        }
        
        return totalWidth + 10
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}


extension Tag: Hashable {
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        if lhs.id == rhs.id, lhs.name == rhs.name { return true }
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
}
