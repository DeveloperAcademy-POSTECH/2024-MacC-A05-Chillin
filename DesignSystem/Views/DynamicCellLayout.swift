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
    let screenWidth: CGFloat
    
    var body: some View {
        generateLayout(items: data)
    }
    
    private func generateLayout(items: Data) -> some View {
        //let screenWidth = UIScreen.main.bounds.width
        
        var currentWidth: CGFloat = 0
        var currentArrays = [Data.Element]()
        
        var resultRows = [[Data.Element]]()
        
        print("🔥현재 너비 : \(screenWidth)")
        var itemWidth2: CGFloat = 0
        
        for (index, item) in items.enumerated() {
            let itemWidth = item.getCellWidth() + 16
            itemWidth2 = itemWidth
            if currentWidth + itemWidth + 20 >= screenWidth {
                resultRows.append(currentArrays)
                currentArrays.removeAll()
                currentWidth = 0
            }
            
            if index == items.count - 1 {
                currentArrays.append(item)
                resultRows.append(currentArrays)
                break
            }
            
            currentWidth += itemWidth + 10
            currentArrays.append(item)
            
            print("🔥더한 너비\(index) : \(currentWidth)")
        }
        print("🔥아이템 너비 : \(itemWidth2)")
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
