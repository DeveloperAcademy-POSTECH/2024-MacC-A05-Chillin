//
//  TableCell.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI

// MARK: - 쿠로꺼 : TableView 커스텀 리스트 셀
struct TableCell: View {
  
  let index: Int
  
  var body: some View {
    HStack(spacing: 0) {
      Image(systemName: "chevron.right")
        .resizable()
        .scaledToFit()
        .frame(height: 10)
        .padding(.trailing, 6)
      
      Text("\(index + 1) Introduction")
        .font(.system(size: 14))
    }
  }
}

#Preview {
  TableCell(index: 0)
}
