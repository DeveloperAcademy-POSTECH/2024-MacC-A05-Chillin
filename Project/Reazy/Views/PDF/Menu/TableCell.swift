//
//  TableCell.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import PDFKit

// MARK: - 쿠로꺼 : TableView 커스텀 리스트 셀
struct TableCell: View {
    
    //let index: Int
    @State var item: TableItem
    @Binding var selected: PDFDestination?
    
    var body: some View {
        if item.children.isEmpty {
            Text(item.table.label ?? "None")
                .onTapGesture {
                    if let destination = item.table.destination {
                        selected = destination
                    } else {
                        print("No destination")
                    }
                }
        } else{
            DisclosureGroup(isExpanded: $item.isExpanded) {
                ForEach(item.children) { child in
                    TableCell(item: child, selected: $selected)
                }
            } label: {
                Text(item.table.label ?? "None")
                    .onTapGesture {
                        if let destination = item.table.destination {
                            selected = destination
                        } else {
                            print("No destination")
                        }
                    }
            }
        }
    }
}

//#Preview {
//    TableCell(item: <#TableItem#>, selectedDestination: <#Binding<PDFDestination?>#>)
//}
