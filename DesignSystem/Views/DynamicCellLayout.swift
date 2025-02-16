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
    let data: Data
    let action: (String) -> Void
    
    var body: some View {
        generateLayout(items: data)
    }
    
    private func generateLayout(items: Data) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        
        var currentWidth: CGFloat = 0
        var currentArrays = [Data.Element]()
        
        var resultRows = [[Data.Element]]()
        
        
        for (index, item) in items.enumerated() {
            let itemWidth = item.getCellWidth()
            
            if currentWidth + itemWidth >= screenWidth {
                resultRows.append(currentArrays)
                currentArrays.removeAll()
                currentWidth = 0
            }
            
            if index == items.count - 1 {
                currentArrays.append(item)
                resultRows.append(currentArrays)
                break
            }
            
            currentWidth += itemWidth
            currentArrays.append(item)
        }
        
        return VStack(alignment: .leading) {
            ForEach(resultRows, id: \.self) { row in
                HStack {
                    ForEach(row) { tag in
                        PDFTagCell(tag: tag) {
                            action(tag.name)
                        }
                    }
                }
            }
        }
    }
}
