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
    
    let tableViewModel: TableViewModel = .init()
    
    @State var outlineItems: [TableItem] = []
    //var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            if outlineItems.isEmpty {
                Text("No table of contents")
            } else {
                List {
                    ForEach(outlineItems) { item in
                        TableCell(item: item)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                    }
                }
                .listStyle(.plain)
            }
        }
        //.padding(.horizontal, 10)
        .onAppear {
            if let document = originalViewModel.document{
                outlineItems = tableViewModel.extractToc(from: document)
            } else {
                outlineItems = []
            }
        }
    }
}
