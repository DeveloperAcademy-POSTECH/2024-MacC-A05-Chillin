//
//  PaperListView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

// MARK: - 홈 뷰 : 논문 리스트 뷰
struct PaperListView: View {
  
  @State private var selectedPaper: Int? = nil
  
  @State private var isStarSelected: Bool = false
  @State private var isFolderSelected: Bool = false
  @State private var isSaveSelected: Bool = false
  @State private var nonselectedIcons: [String] = ["star", "folder.badge.plus", "square.and.arrow.down"]
  @State private var selectedIcons: [String] = ["star.fill", "folder.fill", "checkmark.square.fill"]
  
  @Binding var navigationPath: NavigationPath
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("논문")
          .font(.title)
          .bold()
          .padding(.leading, 26)
        Spacer()
        
        Button(action: {
          
        }) {
          Image(systemName: "checkmark.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(Color(hex: "2F2C9F"))
        }
        .padding(.trailing, 30)
        
        Button(action: {
          
        }) {
          HStack(spacing: 0) {
            Image(systemName: "plus")
              .resizable()
              .scaledToFit()
              .frame(width: 15)
              .padding(.trailing, 6)
            Text("업로드")
              .fontWeight(.semibold)
          }
          .foregroundStyle(Color(hex: "2F2C9F"))
        }
        .padding(.trailing, 45)
      }
      .padding(.vertical, 20)
      
      Divider()
      
      // 화면 비율에 따라서 리스트 크기 설정 (반응형 UI)
      GeometryReader { geometry in
        HStack(spacing: 0) {
          // MARK: - CoreData
          List(content: {
            ForEach(0..<10, id: \.self) { index in
              PaperListCell(
                index: index,
                isSelected: selectedPaper == index,
                onSelect: {
                  selectedPaper = index
                },
                onNavigate: {
                  navigationPath.append(index)
                }
              )
                .listRowBackground(Color.clear)
            }
          })
          .frame(width: geometry.size.width * 0.4)
          .listStyle(.plain)
          
          // 세로 Divider
          Rectangle()
            .frame(width: 1)
            .foregroundStyle(Color(hex: "D9DBE9"))
          
          VStack(spacing: 0) {
            HStack {
              Spacer()
              Text("1/16")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "8B8AAC"))
                .padding(.vertical, 3)
                .padding(.horizontal, 12)
                .background(
                  RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "F0F0F7"))
                )
              Spacer()
            }
            .padding(.bottom, 16)
            
            HStack(spacing: 0) {
              Spacer()
              // MARK: - 문서 첫 페이지
              Rectangle()
                .frame(width: 485, height: 626)
                .foregroundStyle(.gray)
                .padding(.leading)
              
              // 북마크 버튼
              VStack(spacing: 0) {
                Button(action: {
                  isStarSelected.toggle()
                }) {
                  RoundedRectangle(cornerRadius: 14)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color(hex: "EFEFF8"))
                    .overlay(
                      Image(systemName: isStarSelected ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 19)
                        .foregroundStyle(Color(hex: "9092A9"))
                    )
                }
                .padding(.bottom, 11)
                
                // 폴더 저장
                Button(action: {
                  isFolderSelected.toggle()
                }) {
                  RoundedRectangle(cornerRadius: 14)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color(hex: "EFEFF8"))
                    .overlay(
                      Image(systemName: isFolderSelected ? "folder.fill" : "folder.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 19)
                        .foregroundStyle(Color(hex: "9092A9"))
                    )
                }
                .padding(.bottom, 11)
                
                // ?? 버튼
                Button(action: {
                  isSaveSelected.toggle()
                }) {
                  RoundedRectangle(cornerRadius: 14)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color(hex: "EFEFF8"))
                    .overlay(
                      Image(systemName: isSaveSelected ? "checkmark.square.fill" : "square.and.arrow.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 19)
                        .foregroundStyle(Color(hex: "9092A9"))
                    )
                }
                
                Spacer()
              }
              .padding(.leading, 16)
              .padding(.top, 2)
              .frame(height: 626)
              
              Spacer()
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            LinearGradient(
              gradient: Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Color(hex: "D2D4E5"), location: 1)
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .ignoresSafeArea()
        }
      }
    }
    .ignoresSafeArea()
  }
}

#Preview {
  PaperListView(navigationPath: .constant(NavigationPath()))
}
