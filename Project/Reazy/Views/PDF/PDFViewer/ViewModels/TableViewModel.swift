//
//  TableViewModel.swift
//  Reazy
//
//  Created by 김예림 on 10/18/24.
//

import Foundation
import PDFKit

struct TableViewModel {
    
    var tableItems: [TableItem] = []
    var selectedTable: PDFDestination? = nil
    
    func extractToc(from document: PDFDocument) -> [TableItem] {
        var tableItems: [TableItem] = []
        
        if let outlineRoot = document.outlineRoot {
            fetchToc(table: outlineRoot, level: 0, parentArray: &tableItems)
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

struct TableItem: Identifiable {
    let id = UUID()
    let table: PDFOutline
    let level: Int
    var children: [TableItem] = []
    var isExpanded: Bool = false
}
