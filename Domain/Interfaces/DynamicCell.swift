//
//  DynamicCell.swift
//  Reazy
//
//  Created by 문인범 on 2/19/25.
//

import Foundation


protocol DynamicCell: Hashable, Identifiable {
    var id: UUID { get }
    var name: String { get }
    var isSelected: Bool { get set }
    
    func getCellWidth() -> CGFloat
}

extension DynamicCell {
    func itemWidth(isEditMode: Bool) -> CGFloat {
        let padding: CGFloat = isEditMode ? 35 : 16
        return getCellWidth() + padding
    }
}
