//
//  PageView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI

// MARK: - 무니꺼(?) : 페이지 뷰
struct PageView: View {
  var body: some View {
    VStack(spacing: 0) {
      List {
        ForEach(0..<10, id: \.self) { index in
          HStack(spacing: 0){
            Spacer()
            PageCell(index: index)
            Spacer()
          }
          .padding(.bottom, 24)
          .listRowSeparator(.hidden)
        }
      }
      .listStyle(.plain)
      .padding(.top, 24)
    }
  }
}

#Preview {
  PageView()
}
