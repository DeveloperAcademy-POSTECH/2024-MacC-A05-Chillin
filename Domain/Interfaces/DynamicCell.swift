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
    
    func getCellWidth() -> CGFloat
}

extension DynamicCell {
    func itemWidth(isEditMode: Bool) -> CGFloat {
        let additionalPadding: CGFloat = isEditMode ? 40 : 16
        return getCellWidth() + additionalPadding
    }
}
