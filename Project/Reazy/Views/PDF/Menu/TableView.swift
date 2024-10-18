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
    
    let originalViewModel: OriginalViewModel
    let tableViewModel: TableViewModel = .init()
    
    @State var outlineItems: [TableItem] = []
    @State var selectedDestination: PDFDestination? = nil
    
    var body: some View {
        VStack {
            if outlineItems.isEmpty {
                Text("No table of contents")
            } else {
                List {
                    ForEach(outlineItems) { item in
                        TableCell(item: item, selected: $selectedDestination)
                    }
                }
            }
        }.onAppear {
            if let document = originalViewModel.document{
                outlineItems = tableViewModel.extractToc(from: document)
            } else {
                outlineItems = []
            }
        }
    }
}

//#Preview {
//    TableView(tableViewModel: TableViewModel(
//        pdfURL: <#URL#>,
//        pdfDocument: <#PDFDocument#>))
//}
