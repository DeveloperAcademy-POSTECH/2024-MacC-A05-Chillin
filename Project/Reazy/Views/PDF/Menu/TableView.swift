//
//  TableView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import PDFKit

let models: [Model] = [Model(id: .init(), title: "1.Introduction", children: [
    Model(id: .init(), title: "1.1. Contribution", children: [], isExpanded: false),
    Model(id: .init(), title: "1.2. Organization", children: [
        Model(id: .init(), title: "1.2.1 Organization", children: [], isExpanded: false)
    ], isExpanded: false),
    Model(id: .init(), title: "1.3. Contribution", children: [], isExpanded: false)
], isExpanded: false)]

// MARK: - 쿠로꺼 : 목차 뷰
struct TableView: View {
    
    @EnvironmentObject var originalViewModel: OriginalViewModel
    let tableViewModel: TableViewModel = .init()
    @State var outlineItems: [TableItem] = []
    @State var selectedID: UUID?
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer().frame(height: 16)
            
            if outlineItems.isEmpty {
                Text("No table of contents")
            } else {
                ForEach(outlineItems) { item in
                    TableCell(item: item)
                }
            }
            Spacer()
            
            //                List {
            //                    ForEach(outlineItems) { item in
            //                        TableCell(models: Model)
            ////                            .listRowBackground(Color.clear)
            ////                            .listRowSeparator(.hidden)
            ////                            .accentColor(.gray800)
            //                    }
            //                }
            //                .listStyle(.plain)
            //                .listRowInsets(.none)
            //            }
            //        }
            //        //.padding(.trailing, 5)
        }.onAppear {
            if let document = originalViewModel.document{
                outlineItems = tableViewModel.extractToc(from: document)
            } else {
                outlineItems = []
            }
        }
    }
}


