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
    @Binding var selectedID: UUID?
    
    var body: some View {
        ZStack {
            VStack {
                if selectedID == item.id {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.primary2)
                        .frame(height: 40)
                }
                Spacer()
            }
            VStack{
                if item.children.isEmpty {
                    HStack {
                        Text(item.table.label ?? "None")
                            .lineLimit(1)
                            .reazyFont(.h3)
                            .foregroundStyle(Color(.gray900))
                            .onTapGesture {
                                onTap()
                            }
                        Spacer()
                    }
                    .frame(height: 40)
                } else{
                    DisclosureGroup(isExpanded: $item.isExpanded) {
                        ForEach(item.children) { child in
                            HStack{
                                Spacer().frame(width: 20)
                                TableCell(item: child, selectedID: $selectedID)
                            }
                        }
                    } label: {
                        HStack{
                            Text(item.table.label ?? "None")
                                .lineLimit(1)
                                .reazyFont(.h3)
                                .foregroundStyle(Color(.gray900))
                                .onTapGesture {
                                    onTap()
                                }
                        }
                        .frame(height: 40)
                        .accentColor(.gray800)
                    }
                    .listRowInsets(.init(top: 0, leading: 10, bottom: 0, trailing: 0))
                }
                Spacer()
            }
        }
        //        .background(
        //            selectedID == item.id ? Color.primary2 : Color.clear
        //        )
        //        .cornerRadius(4)
    }
    
    private func onTap() {
        
        if selectedID != item.id {
            selectedID = item.id
            print(selectedID)
        }
        
        if let destination = item.table.destination {
            viewModel.selectedDestination = destination
            //test
            dump(destination)
        } else {
            print("No destination")
        }
    }
}
