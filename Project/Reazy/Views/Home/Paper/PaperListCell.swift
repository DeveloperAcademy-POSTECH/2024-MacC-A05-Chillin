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
  let isEditing: Bool
  let isEditingSelected: Bool
  let onSelect: () -> Void
  let onEditingSelect: () -> Void
  let onNavigate: () -> Void
  
  var body: some View {
    ZStack {
      if isSelected {
        RoundedRectangle(cornerRadius: 14)
          .fill(.primary2)
          .padding(.vertical, 2)
      }
      
      HStack(spacing: 0) {
        if isEditing {
          Image(systemName: isEditingSelected ? "checkmark.circle.fill" : "circle")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(isEditingSelected ? .primary1 : .primary4)
            .onTapGesture {
              onEditingSelect()
            }
            .padding(.trailing, 20)
        }
        
        
        // 논문 표지 들어갈 자리
        Rectangle()
          .fill(.gray)
          .frame(width: 86, height: 112)
        
        VStack(alignment: .leading, spacing: 0) {
          Text("A Review of Generalized Zero-Shot Learning Methods")
            .reazyFont(.h2)
            .padding(.bottom, 4)
          Text("1시간 전")
            .reazyFont(.h4)
            .foregroundStyle(.gray600)
          
          HStack(spacing: 0) {
            Spacer()
            
            if isSelected && !isEditing {
              actionButton()
            } else {
              actionButton()
                .hidden()
            }
          }
        }
        .padding(.leading, 14)
        .padding(.top, 14)
      }
      .background(.clear)
      .padding(.horizontal, 10)
      .padding(.vertical, 10)
      .contentShape(Rectangle())
      .onTapGesture {
        if isEditing {
          onEditingSelect()
        } else {
          onSelect()
        }
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
      .foregroundStyle(.gray100)
      .reazyFont(.button2)
      .padding(.horizontal, 21)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 18)
          .foregroundStyle(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: Color(hex:"3F3E7E"), location: 0),
                .init(color: Color(hex: "313070"), location: 1)
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .shadow(color: Color(hex: "383582").opacity(0.2), radius: 30, x: 0, y: 6)
      )
    }
  }
}

#Preview {
  PaperListCell(
    index: 1,
    isSelected: false,
    isEditing: true,
    isEditingSelected: false,
    onSelect: {},
    onEditingSelect: {},
    onNavigate: {}
  )
}