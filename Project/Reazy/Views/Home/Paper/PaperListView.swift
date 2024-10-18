//
//  PaperListView.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI

struct PaperListView: View {
  
  @State private var selectedPaper: Int? = nil
  
  let isEditing: Bool
  @Binding var selectedItems: Set<Int>
  
  @Binding var navigationPath: NavigationPath
  
  var body: some View {
    // 화면 비율에 따라서 리스트 크기 설정 (반응형 UI)
    GeometryReader { geometry in
      HStack(spacing: 0) {
        // MARK: - CoreData
        List(content: {
          ForEach(0..<10, id: \.self) { index in
            PaperListCell(
              index: index,
              isSelected: selectedPaper == index,
              isEditing: isEditing,
              isEditingSelected: selectedItems.contains(index),
              onSelect: {
                if !isEditing {
                  selectedPaper = index
                }
              },
              onEditingSelect: {
                if isEditing {
                  if selectedItems.contains(index) {
                    selectedItems.remove(index)
                  } else {
                    selectedItems.insert(index)
                  }
                }
              },
              onNavigate: {
                if !isEditing {
                  navigationPath.append(index)
                }
              }
            )
            .listRowBackground(Color.clear)
          }
        })
        .frame(width: geometry.size.width * 0.4)
        .listStyle(.plain)
        .background(Color(hex: "F7F7FB"))
        
        // 세로 Divider
        Rectangle()
          .frame(width: 1)
          .foregroundStyle(.primary3)
        
        VStack(spacing: 0) {
          if isEditing {
            EmptyView()
          } else {
            PaperInfoView()
          }
        }
        .animation(.easeInOut, value: isEditing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
          LinearGradient(
            gradient: Gradient(stops: [
              .init(color: Color(hex: "F7F7FB"), location: 0),
              .init(color: Color(hex: "D2D4E5"), location: isEditing ? 1.5 : 1)
            ]),
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .ignoresSafeArea()
      }
      .background(.clear)
    }
  }
}

#Preview {
  PaperListView(
    isEditing: false,
    selectedItems: .constant([]),
    navigationPath: .constant(NavigationPath()))
}
