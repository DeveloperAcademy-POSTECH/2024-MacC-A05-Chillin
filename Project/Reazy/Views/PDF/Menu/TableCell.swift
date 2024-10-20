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
    @State var isSelected: Bool = false
    
    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.primary2)
            }
            
            if item.children.isEmpty {
                HStack {
                    Text(item.table.label ?? "None")
                        .reazyFont(.h3)
                        .padding(.leading, 14)
                        .padding(.trailing,9)
                        .padding(.vertical, 11)
                        .foregroundStyle(Color(.gray900))
                    
                        .onTapGesture {
                            onTap()
                        }
                    Spacer()
                }
            } else{
                VStack {
                    DisclosureGroup(isExpanded: $item.isExpanded) {
                        ForEach(item.children) { child in
                            TableCell(item: child)
                        }
                    } label: {
                        Text(item.table.label ?? "None")
                            .reazyFont(.h3)
                            .foregroundStyle(Color(.gray900))
                            .padding(.leading, 14)
                            .padding(.trailing,9)
                            .padding(.vertical, 11)
                        
                            .onTapGesture {
                                onTap()
                            }
                    }.accentColor(.gray800)
                }
            }
        }
    }
    
    private func onTap() {
        isSelected.toggle()
        
        if let destination = item.table.destination {
            viewModel.selectedDestination = destination
            //test
            dump(destination)
        } else {
            print("No destination")
        }
    }
}
