//
//  PaperListCell.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

struct PaperListCell: View {
  
  /// 지금은 논문을 분류할 기준이 없어서 index로 대체했습니다
  let index: Int
  let isSelected: Bool
  let onSelect: () -> Void
  let onNavigate: () -> Void
  
  var body: some View {
    ZStack {
      if isSelected {
        RoundedRectangle(cornerRadius: 14)
          .fill(Color(hex: "E4E6F3"))
          .padding(.vertical, 2)
      }
      
      HStack(spacing: 0) {
        Rectangle()
          .fill(.gray)
          .frame(width: 86, height: 112)
        
        VStack(alignment: .leading, spacing: 0) {
          Text("A Review of Generalized Zero-Shot Learning Methods")
            .font(.system(size: 16))
            .padding(.bottom, 6)
          Text("1시간 전")
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "9092A9"))
          
          HStack() {
            Spacer()
            
            if isSelected {
              actionButton()
            } else {
              actionButton()
                .hidden()
            }
          }
        }
        .padding(.leading, 14)
      }
      .background(.clear)
      .padding(.horizontal, 10)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
      .onTapGesture {
        onSelect()
      }
      .allowsHitTesting(isSelected == false)
    }
  }
  
  @ViewBuilder
  private func actionButton() -> some View {
    Button(action: {
      onNavigate()  // "읽기" 버튼 클릭
    }) {
      HStack(spacing: 0) {
        Text("읽기 ")
        Image(systemName: "arrow.up.right")
      }
      .foregroundStyle(.white)
      .font(.system(size: 14))
      .padding(.horizontal, 21)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 18)
          .fill(Color(hex: "3F3E7E"))
      )
    }
  }
}
