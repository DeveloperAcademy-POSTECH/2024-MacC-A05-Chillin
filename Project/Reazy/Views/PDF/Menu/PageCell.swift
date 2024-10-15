//
//  SwiftUIView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI

// MARK: - 무니꺼(?) : PageView 커스텀 리스트 셀
struct PageCell: View {
  
  let index: Int
  
  var body: some View {
    HStack(spacing: 0) {
      VStack(spacing: 0) {
        Text("\(index + 1)")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color(hex: "625FB1"))
        Spacer()
      }
      .padding(.trailing, 19)
      
      VStack(spacing: 0) {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(.white)
            .frame(width: 152, height: 200)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(lineWidth: 1)
                .fill(Color(hex: "CDCFE1"))
                .frame(width: 152, height: 200)
            )
        }
        
        Spacer()
      }
    }
  }
}

#Preview {
  PageCell(index: 0)
}
