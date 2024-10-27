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
    
    @EnvironmentObject var originalViewModel: MainPDFViewModel
    
    @State var tableViewModel: TableViewModel = .init()
    @State var selectedID: UUID? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if tableViewModel.tableItems.isEmpty {
                    Text("개요가 있으면,\n여기에 표시됩니다")
                        .reazyFont(.h3)
                        .foregroundStyle(Color.gray600)
                        .padding(.top, 302)
                } else {
                    ForEach(tableViewModel.tableItems) { item in
                        TableCell(item: item, selectedID: $selectedID)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
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


