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
  
  // MARK: - 모델 생성 시 수정 필요
  @State private var paperTitle: [String] = ["A review of the global climate change impacts, adaptation, and sustainable mitigation measures"]
  @State private var datetime: [String] = ["2024. 10. 20. 오후 08:56"]
  
  
  var body: some View {
    // 화면 비율에 따라서 리스트 크기 설정 (반응형 UI)
    GeometryReader { geometry in
      HStack(spacing: 0) {
        // MARK: - CoreData
        List(content: {
          ForEach(0..<paperTitle.count, id: \.self) { index in
            PaperListCell(
              // MARK: - 썸네일 이미지 수정 필요
              image: Image("test_thumbnail"),
              title: paperTitle[index],
              date: datetime[index],
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
            // MARK: - 썸네일 이미지 수정 필요
            PaperInfoView(image: Image("test_thumbnail"))
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
