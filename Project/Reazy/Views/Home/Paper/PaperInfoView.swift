//
//  PaperInfoView.swift
//  Reazy
//
//  Created by 유지수 on 10/18/24.
//

import SwiftUI

struct PaperInfoView: View {
  
  // MARK: - 썸네일 이미지 수정 필요
  let image: Image
  let author: String
  let year: String
  let pages: Int
  let publisher: String
  
  @State private var isStarSelected: Bool = false
  @State private var isFolderSelected: Bool = false
  
  let onNavigate: () -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      // MARK: - 문서 첫 페이지
      image
        .resizable()
        .scaledToFit()
        .padding(.horizontal, 30)
      
      // 북마크 버튼
      HStack(spacing: 0) {
        actionButton()
        
        Spacer()
        
        Button(action: {
          isStarSelected.toggle()
        }) {
          RoundedRectangle(cornerRadius: 14)
            .frame(width: 40, height: 40)
            .foregroundStyle(.gray400)
            .overlay(
              Image(systemName: isStarSelected ? "star.fill" : "star")
                .resizable()
                .scaledToFit()
                .frame(height: 17)
                .foregroundStyle(.gray600)
            )
        }
        .padding(.trailing, 6)
        
        // 삭제 버튼
        Button(action: {
          
        }) {
          RoundedRectangle(cornerRadius: 14)
            .frame(width: 40, height: 40)
            .foregroundStyle(.gray400)
            .overlay(
              Image(systemName: "trash")
                .resizable()
                .scaledToFit()
                .frame(height: 17)
                .foregroundStyle(.gray600)
            )
        }
        .padding(.trailing, 6)
        
        // 폴더 저장
        Button(action: {
          isFolderSelected.toggle()
        }) {
          RoundedRectangle(cornerRadius: 14)
            .frame(width: 40, height: 40)
            .foregroundStyle(.gray400)
            .overlay(
              Image(systemName: isFolderSelected ? "folder.fill" : "folder.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(height: 17)
                .foregroundStyle(.gray600)
            )
        }
      }
      .padding(.horizontal, 30)
      .padding(.top, 18)
      
      VStack(spacing: 0) {
        Divider()
          .padding(.bottom, 6)
          .foregroundStyle(.primary3)
        HStack(spacing: 0) {
          Text("정보")
            .reazyFont(.button1)
          
          Spacer()
        }
        .padding(.bottom, 6)
        
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            Text("저자")
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 데이터 입력 필요
            Text(author)
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
          }
          Divider()
            .padding(.vertical, 9)
            .foregroundStyle(.primary3)
          HStack(spacing: 0) {
            Text("출판연도")
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 데이터 입력 필요
            Text(year)
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
          }
          Divider()
            .padding(.vertical, 9)
            .foregroundStyle(.primary3)
          HStack(spacing: 0) {
            Text("페이지")
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 데이터 입력 필요
            Text("\(pages)")
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
          }
          Divider()
            .padding(.vertical, 9)
            .foregroundStyle(.primary3)
          HStack(spacing: 0) {
            Text("학술지")
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 데이터 입력 필요
            Text(publisher)
              .reazyFont(.text1)
              .foregroundStyle(.gray600)
          }
          Divider()
            .padding(.vertical, 9)
            .foregroundStyle(.primary3)
        }
      }
      .padding(.top, 24)
      .padding(.horizontal, 30)
      
      Spacer()
    }
    .padding(.top, 37)
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
    .frame(height: 40)
  }
}

#Preview {
  PaperInfoView(
    image: Image("image"),
    author: "Smith, John",
    year: "2010",
    pages: 43,
    publisher: "NATURE",
    onNavigate: {}
  )
}
