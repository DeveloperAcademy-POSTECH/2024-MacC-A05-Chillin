//
//  FigureView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI

// MARK: - 루시드꺼 : Figure 뷰
struct FigureView: View {
  var body: some View {
    VStack(spacing: 0) {
      Text("피규어를 꺼내서 창에 띄울 수 있어요")
        .font(.system(size: 12))
        .foregroundStyle(Color(hex: "9395A9"))
        .padding(.vertical, 24)
      
      List {
        ForEach(0..<10, id: \.self) { index in
          FigureCell()
            .padding(.bottom, 21)
            .listRowSeparator(.hidden)
        }
      }
      .listStyle(.plain)
    }
  }
}

#Preview {
  FigureView()
}
