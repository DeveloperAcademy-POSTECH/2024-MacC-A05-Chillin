//
//  Tag.swift
//  Reazy
//
//  Created by 김예림 on 2/9/25.
//

import Foundation

struct Tag: Identifiable {
    let id: UUID
    let title: String
    var isSelected: Bool
}
