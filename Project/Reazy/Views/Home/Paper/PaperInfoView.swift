//
//  PaperInfoView.swift
//  Reazy
//
//  Created by 유지수 on 10/18/24.
//

import SwiftUI

struct PaperInfoView: View {
  
  let image: Image
  let title: String
  let author: String
  let year: String
  let pages: Int
  let publisher: String
  
  @State private var isStarSelected: Bool = false
  
  let onNavigate: () -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      image
        .resizable()
        .frame(height: 380)
        .scaledToFit()
        .padding(.horizontal, 30)
      
      Text(title)
        .reazyFont(.text1)
        .foregroundStyle(.gray900)
        .padding(.horizontal, 30)
        .padding(.top, 13)
        .lineLimit(2)
      
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
                .foregroundStyle(isStarSelected ? .primary1 : .gray600)
            )
        }
        .padding(.trailing, 6)
          
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
        
        Button(action: {
          
        }) {
          RoundedRectangle(cornerRadius: 14)
            .frame(width: 40, height: 40)
            .foregroundStyle(.gray400)
            .overlay(
              Image(systemName: "ellipsis.circle")
                .resizable()
                .scaledToFit()
                .frame(height: 17)
                .foregroundStyle(.gray600)
            )
        }
      }
      .padding(.horizontal, 30)
      .padding(.top, 20)
      
      VStack(spacing: 0) {
        Rectangle()
          .frame(height: 1)
          .padding(.bottom, 10)
          .foregroundStyle(.primary3)
        
        HStack(spacing: 0) {
          Text("정보")
            .reazyFont(.button1)
            .foregroundStyle(.black)
          
          Spacer()
        }
        .padding(.bottom, 15)
        
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            Text("저자")
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 저자 데이터 입력 필요
            Text(author)
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
          }
          Rectangle()
            .frame(height: 1)
            .padding(.top, 1)
            .padding(.bottom, 10)
            .foregroundStyle(.primary3)
          HStack(spacing: 0) {
            Text("출판연도")
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 출판연도 데이터 입력 필요
            Text(year)
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
          }
          Rectangle()
            .frame(height: 1)
            .padding(.top, 1)
            .padding(.bottom, 10)
            .foregroundStyle(.primary3)
          HStack(spacing: 0) {
            Text("페이지")
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 페이지 수 데이터 입력 필요
            Text("\(pages)")
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
          }
          Rectangle()
            .frame(height: 1)
            .padding(.top, 1)
            .padding(.bottom, 10)
            .foregroundStyle(.primary3)
          HStack(spacing: 0) {
            Text("학술지")
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
            
            Spacer()
            
            // TODO: - 학술지 데이터 입력 필요
            Text(publisher)
              .reazyFont(.button5)
              .foregroundStyle(.gray600)
          }
          Rectangle()
            .frame(height: 1)
            .padding(.top, 1)
            .padding(.bottom, 10)
            .foregroundStyle(.primary3)
        }
      }
      .padding(.top, 24)
      .padding(.horizontal, 30)
      
      Spacer()
    }
    .padding(.top, 36)
  }
  
  
  @ViewBuilder
  private func actionButton() -> some View {
    Button(action: {
      onNavigate()
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
    title: "A review of the global climate change impacts, adaptation, and sustainable mitigation measures",
    author: "Smith, John",
    year: "2010",
    pages: 43,
    publisher: "NATURE",
    onNavigate: {}
  )
}
