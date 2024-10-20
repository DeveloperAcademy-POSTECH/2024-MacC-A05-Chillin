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
    @State var selectedID: UUID?
    
    var body: some View {
        VStack {
            if outlineItems.isEmpty {
                Text("No table of contents")
            } else {
                List {
                    ForEach(outlineItems) { item in
                        TableCell(item: item, selectedID: $selectedID)
                        //.frame(height: 40)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accentColor(.gray800)
                    }
                }
                .listStyle(.plain)
                .listRowInsets(.none)
            }
        }
        .onAppear {
            if let document = originalViewModel.document{
                outlineItems = tableViewModel.extractToc(from: document)
            } else {
                outlineItems = []
            }
        }
    }
}
