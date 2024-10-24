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
    @State var selectedID: UUID? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if outlineItems.isEmpty {
                    Text("No table of contents")
                } else {
                    ForEach(outlineItems) { item in
                        TableCell(item: item, selectedID: $selectedID)
                    }
                }
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.smooth(duration: 0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
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


