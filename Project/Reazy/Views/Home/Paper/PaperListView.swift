//
//  PaperListView.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI

struct PaperListView: View {
  
  @Binding var navigationPath: NavigationPath
  
  @State private var selectedPaper: Int = 0
  
  @Binding var isEditing: Bool
  @State var selectedItems: Set<Int> = []
  
  @Binding var isSearching: Bool
  
  @State private var isFavoritesSelected: Bool = false
  
  // MARK: - Core Data 모델 생성 시 수정 필요 : 예시 데이터
  @State var papers: [PaperInfo] = [PaperInfo(
    title: "A review of the global climate change impacts, adaptation, and sustainable mitigation measures",
    datetime: "2024. 10. 20. 오후 08:56",
    author: "Smith, John",
    year: "2010",
    pages: 43,
    publisher: "NATURE"
  )]

  
  var body: some View {
    // 화면 비율에 따라서 리스트 크기 설정 (반응형 UI)
    GeometryReader { geometry in
      HStack(spacing: 0) {
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            Spacer()
            
            Button(action: {
              isFavoritesSelected = false
            }, label: {
              Text("전체 논문")
                .reazyFont(isFavoritesSelected ? .h2 : .text3)
                .foregroundStyle(isFavoritesSelected ? .primary4 : .primary1)
            })
            
            Rectangle()
              .foregroundStyle(.gray500)
              .frame(width: 1, height: 20)
              .padding(.horizontal, 16)
            
            Button(action: {
              isFavoritesSelected = true
              // TODO: - 즐겨찾기 filter 적용 필요
            }, label: {
              Text("즐겨찾기")
                .reazyFont(isFavoritesSelected ? .text3 : .h2)
                .foregroundStyle(isFavoritesSelected ? .primary1 : .primary4)
            })
            
            Spacer()
          }
          .padding(.leading, 28)
          .padding(.vertical, 20)
          
          Divider()
          
          // MARK: - CoreData
          List(content: {
            ForEach(0..<papers.count, id: \.self) { index in
              PaperListCell(
                title: papers[index].title,
                date: papers[index].dateTime,
                isSelected: selectedPaper == index,
                isEditing: isEditing,
                isEditingSelected: selectedItems.contains(index),
                onSelect: {
                  if !isEditing {
                    if selectedPaper == index {
                      navigationPath.append(selectedPaper)
                    } else {
                      selectedPaper = index
                    }
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
                }
              )
              .listRowBackground(Color.clear)
            }
          })
        }
        .frame(width: isEditing || isSearching ? geometry.size.width : geometry.size.width * 0.7)
        .listStyle(.plain)
        .background(.gray300)
        
        // 편집 모드 & 검색 모드에서는 문서 정보가 보이지 않아야 함
        if !isEditing && !isSearching {
          Rectangle()
            .frame(width: 1)
            .foregroundStyle(.primary3)
          
          VStack(spacing: 0) {
            // MARK: - 썸네일 이미지 수정 필요
            PaperInfoView(
              image: Image("test_thumbnail"),
              author: papers[selectedPaper].author,
              year: papers[selectedPaper].year,
              pages: papers[selectedPaper].pages,
              publisher: papers[selectedPaper].publisher,
              onNavigate: {
                if !isEditing {
                  navigationPath.append(selectedPaper)
                }
              }
            )
          }
          .animation(.easeInOut, value: isEditing)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: .gray300, location: 0),
                .init(color: Color(hex: "DADBEA"), location: isEditing ? 3.5 : 4)
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
        }
      }
      .background(.gray200)
      .ignoresSafeArea()
    }
  }
}

#Preview {
  PaperListView(
    navigationPath: .constant(NavigationPath()),
    isEditing: .constant(false),
    isSearching: .constant(false),
    papers: [PaperInfo(
      title: "A review of the global climate change impacts, adaptation, and sustainable mitigation measures",
      datetime: "2024. 10. 20. 오후 08:56",
      author: "Smith, John",
      year: "2010",
      pages: 43,
      publisher: "NATURE")]
  )
}
