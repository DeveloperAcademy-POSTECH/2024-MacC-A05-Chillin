//
//  TableView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import PDFKit


// MARK: - 쿠로꺼 : 목차 뷰
struct IndexView: View {
    @EnvironmentObject private var indexViewModel: IndexViewModel
    
    @State var selectedID: UUID? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if indexViewModel.tableItems.isEmpty {
                    Text("목차가 있으면,\n여기에 표시됩니다")
                        .multilineTextAlignment(.center)
                        .reazyFont(.body3)
                        .foregroundStyle(.gray600)
                        .padding(.top, 302)
                } else {
                    ForEach(indexViewModel.tableItems) { item in
                        IndexCell(item: item, selectedID: $selectedID)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            indexViewModel.extractIndex()
        }
    }
}


