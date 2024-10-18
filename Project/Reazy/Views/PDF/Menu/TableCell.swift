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
    @EnvironmentObject var viewModel: OriginalViewModel
    @State var item: TableItem
    
    var body: some View {
        if item.children.isEmpty {
            Text(item.table.label ?? "None")
                .onTapGesture {
                    onTap()
                }
        } else{
            DisclosureGroup(isExpanded: $item.isExpanded) {
                ForEach(item.children) { child in
                    TableCell(item: child)
                }
            } label: {
                Text(item.table.label ?? "None")
                    .onTapGesture {
                        onTap()
                    }
            }
        }
    }
    
    private func onTap() {
        if let destination = item.table.destination {
            viewModel.selectedDestination = destination
            //test
            dump(destination)
        } else {
            print("No destination")
        }
    }
}
