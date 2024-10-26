//
//  TableView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import PDFKit


// MARK: - 쿠로꺼 : 목차 뷰
struct TableView: View {

    @EnvironmentObject var originalViewModel: OriginalViewModel
    
    @State var tableViewModel: TableViewModel = .init()
    @State var selectedID: UUID? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if tableViewModel.tableItems.isEmpty {
                    Text("개요가 있으면,\n여기에 표시됩니다")
                        .reazyFont(.h3)
                        .foregroundStyle(Color.gray600)
                } else {
                    ForEach(tableViewModel.tableItems) { item in
                        TableCell(item: item, selectedID: $selectedID)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear {
            if let document = originalViewModel.document{
                tableViewModel.tableItems = tableViewModel.extractToc(from: document)
            } else {
                tableViewModel.tableItems = []
            }
        }
    }
}


