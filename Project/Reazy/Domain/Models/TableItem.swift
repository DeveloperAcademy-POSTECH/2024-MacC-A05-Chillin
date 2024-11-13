//
//  TableItem.swift
//  Reazy
//
//  Created by 문인범 on 10/19/24.
//

import Foundation
import PDFKit

struct TableItem: Identifiable {
    let id = UUID()
    let table: PDFOutline
    let level: Int
    var children: [TableItem] = []
    var isExpanded: Bool = false
}
