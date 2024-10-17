//
//  PaperListView.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI

struct PaperListView: View {
  
  @State private var selectedPaper: Int? = nil
  
  @State private var isStarSelected: Bool = false
  @State private var isFolderSelected: Bool = false
  
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
          .foregroundStyle(.primary3)
        
        VStack(spacing: 0) {
          HStack {
            Spacer()
            Text("1/16")
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
              .padding(.vertical, 3)
              .padding(.horizontal, 12)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(.gray300)
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
                  .foregroundStyle(.gray300)
                  .overlay(
                    Image(systemName: isStarSelected ? "star.fill" : "star")
                      .resizable()
                      .scaledToFit()
                      .frame(height: 17)
                      .foregroundStyle(.gray600)
                  )
              }
              .padding(.bottom, 11)
              
              // 삭제 버튼
              Button(action: {
                
              }) {
                RoundedRectangle(cornerRadius: 14)
                  .frame(width: 40, height: 40)
                  .foregroundStyle(.gray300)
                  .overlay(
                    Image(systemName: "trash")
                      .resizable()
                      .scaledToFit()
                      .frame(height: 17)
                      .foregroundStyle(.gray600)
                  )
              }
              .padding(.bottom, 11)
              
              // 폴더 저장
              Button(action: {
                isFolderSelected.toggle()
              }) {
                RoundedRectangle(cornerRadius: 14)
                  .frame(width: 40, height: 40)
                  .foregroundStyle(.gray300)
                  .overlay(
                    Image(systemName: isFolderSelected ? "folder.fill" : "folder.badge.plus")
                      .resizable()
                      .scaledToFit()
                      .frame(height: 17)
                      .foregroundStyle(.gray600)
                  )
              }
              .padding(.bottom, 11)
              
              // 내보내기 버튼
              Button(action: {
                
              }) {
                RoundedRectangle(cornerRadius: 14)
                  .frame(width: 40, height: 40)
                  .foregroundStyle(.gray300)
                  .overlay(
                    Image(systemName: "square.and.arrow.up")
                      .resizable()
                      .scaledToFit()
                      .frame(height: 17)
                      .foregroundStyle(.gray600)
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
      .background(.clear)
    }
  }
}

#Preview {
  PaperListView(navigationPath: .constant(NavigationPath()))
}
