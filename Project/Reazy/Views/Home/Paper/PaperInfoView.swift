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
  
  @State private var isStarSelected: Bool = false
  @State private var isFolderSelected: Bool = false
  
  var body: some View {
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
      image
        .resizable()
        .scaledToFit()
        .frame(width: 460)
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
}

#Preview {
  PaperInfoView(image: Image("image"))
}
