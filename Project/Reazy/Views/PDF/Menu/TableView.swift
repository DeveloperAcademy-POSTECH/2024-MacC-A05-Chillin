//
//  TableView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI

// MARK: - 쿠로꺼 : 목차 뷰
struct TableView: View {
  var body: some View {
    List {
      ForEach(0..<10, id: \.self) { index in
        TableCell(index: index)
          .listRowSeparator(.hidden)
          .padding(.top, 16)
          .padding(.leading, 24)
      }
    }
    .listStyle(.plain)
  }
}

#Preview {
  TableView()
}
