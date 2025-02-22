//
//  DynamicCellLayout.swift
//  Reazy
//
//  Created by 문인범 on 2/13/25.
//

import SwiftUI

/**
 Cell들의 폭의 반응하여 List를 만드는 구조체
 */
struct DynamicCellLayout<Data: RandomAccessCollection>: View where Data.Element: DynamicCell {
    @EnvironmentObject var tagViewModel: TagViewModel
    let data: Data
    let action: (String) -> Void
    let screenWidth: CGFloat
    let isMultiSelectable: Bool
    
    var body: some View {
        generateLayout(items: data)
    }
    
    private func generateLayout(items: Data) -> some View {
        
        var currentWidth: CGFloat = 0
        var currentArrays = [Data.Element]()
        
        var resultRows = [[Data.Element]]()
        
        for (index, item) in items.enumerated() {
            let itemWidth = item.itemWidth(isEditMode: tagViewModel.isEditMode)
            if currentWidth + itemWidth + 10 >= screenWidth {
                resultRows.append(currentArrays)
                currentArrays.removeAll()
                currentWidth = 0
            }
            
            if index == items.count - 1 {
                currentArrays.append(item)
                resultRows.append(currentArrays)
                break
            }
            
            currentWidth += itemWidth + 20
            currentArrays.append(item)
        }
        return VStack(alignment: .leading) {
            ForEach(resultRows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row) { tag in
                        PDFTagCell(isMultiSelectable: isMultiSelectable, tag: tag) {
                            action(tag.name)
                        }
                    }
                }
            }
            .padding(.bottom, 10)
        }
    }
}
