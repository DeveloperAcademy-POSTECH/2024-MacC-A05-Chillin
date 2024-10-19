//
//  TableViewModel.swift
//  Reazy
//
//  Created by 김예림 on 10/18/24.
//

import Foundation
import PDFKit

struct TableViewModel {
    
    func extractToc(from document: PDFDocument) -> [TableItem] {
        var tableItems: [TableItem] = []
        
        if let outlineRoot = document.outlineRoot {
            //outlineRoot의 자식이 하나면 제외하고 fetch 돌리기
            if outlineRoot.numberOfChildren == 1{
                if let child = outlineRoot.child(at: 0) {
                    fetchToc(table: child, level: 0, parentArray: &tableItems)
                }
            } else {
                fetchToc(table: outlineRoot, level: 0, parentArray: &tableItems)
            }
        }
        
        func fetchToc(table: PDFOutline, level: Int, parentArray: inout [TableItem]) {
            
            for index in 0..<table.numberOfChildren {
                if let child = table.child(at: index) {
                    let newItem = TableItem(table: child, level: level, children: [])
                    parentArray.append(newItem)
                    fetchToc(table: child, level: level + 1, parentArray: &parentArray[parentArray.count - 1].children)
                }
            }
        }
        return tableItems
    }
}