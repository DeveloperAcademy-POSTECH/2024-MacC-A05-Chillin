//
//  PDFView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

struct PDFView: View {
  
  // 문서 선택 확인을 위한 인덱스
  let index: Int
  
  // 모드 구분
  @State private var selectedMode = "원문 모드"
  var mode = ["원문 모드", "집중 모드"]
  
  // 모아보기 버튼 구분
  @State private var isSelected: [Bool] = [false, false, false]
  @State private var icons: [String] = ["list.bullet", "rectangle.grid.1x2", "Fig"]
  
  @Binding var navigationPath: NavigationPath
  
  var body: some View {
    VStack(spacing: 0) {
      Divider()
        .foregroundStyle(Color(hex: "CCCEE1"))
      
      ZStack {
        HStack(spacing: 0) {
          // MARK: - 왼쪽 상단 버튼 3개
          /// 버튼 하나가 글자로 이루어져 있어서 분리
          ForEach(0..<isSelected.count, id: \.self) { index in
            if index < 2 {
              Button(action: {
                if isSelected[index] {
                  isSelected[index] = false
                } else {
                  isSelected.toggleSelection(at: index)
                }
              }) {
                RoundedRectangle(cornerRadius: 6)
                  .frame(width: 26, height: 26)
                  .foregroundStyle(isSelected[index] ? Color(hex: "5F5DAA") : .clear)
                  .overlay (
                    Image(systemName: icons[index])
                      .resizable()
                      .scaledToFit()
                      .foregroundStyle(isSelected[index] ? .white : Color(hex: "3C3D4B"))
                      .frame(width: 18)
                  )
              }
              .padding(.trailing, 36)
            } else {
              Button(action: {
                if isSelected[index] {
                  isSelected[index] = false
                } else {
                  isSelected.toggleSelection(at: index)
                }
              }) {
                RoundedRectangle(cornerRadius: 6)
                  .frame(width: 26, height: 26)
                  .foregroundStyle(isSelected[index] ? Color(hex: "5F5DAA") : .clear)
                  .overlay (
                    Text("Fig")
                      .font(.system(size: 14))
                      .foregroundStyle(isSelected[index] ? .white : Color(hex: "3C3D4B"))
                  )
              }
            }
          }
          
          Spacer()
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "link.badge.plus")
              .resizable()
              .scaledToFit()
              .foregroundStyle(Color(hex: "4B4C5C"))
              .frame(width: 21)
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 30)
        .background(Color(hex: "DADDEF"))
        
        HStack(spacing: 0) {
          Spacer()
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "text.bubble")
              .resizable()
              .scaledToFit()
              .foregroundStyle(Color(hex: "3C3D4B"))
              .frame(height: 19)
          }
          .padding(.trailing, 39)
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "character.bubble")
              .resizable()
              .scaledToFit()
              .foregroundStyle(Color(hex: "3C3D4B"))
              .frame(height: 19)
          }
          .padding(.trailing, 39)
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "pencil.tip.crop.circle")
              .resizable()
              .scaledToFit()
              .foregroundStyle(Color(hex: "3C3D4B"))
              .frame(height: 19)
          }
          .padding(.trailing, 39)
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "square.dashed")
              .resizable()
              .scaledToFit()
              .foregroundStyle(Color(hex: "3C3D4B"))
              .frame(height: 19)
          }
          
          Spacer()
        }
      }
      
      Divider()
        .foregroundStyle(Color(hex: "CCCEE1"))
      
      GeometryReader { geometry in
        ZStack {
          if selectedMode == "원문 모드" { OriginalView() }
          else if selectedMode == "집중 모드" { ConcentrateView() }
          
          // MARK: - 모아보기 창
          HStack(spacing: 0){
            if isSelected[0] {
              TableView()
                .background(.white)
                .frame(width: geometry.size.width * 0.25)
              
              Rectangle()
                .frame(width: 1)
                .foregroundStyle(Color(hex: "CCCEE1"))
            } else if isSelected[1] {
              PageView()
                .background(.white)
                .frame(width: geometry.size.width * 0.25)
              
              Rectangle()
                .frame(width: 1)
                .foregroundStyle(Color(hex: "CCCEE1"))
            } else if isSelected[2] {
              FigureView()
                .background(.white)
                .frame(width: geometry.size.width * 0.25)
              
              Rectangle()
                .frame(width: 1)
                .foregroundStyle(Color(hex: "CCCEE1"))
            }
            
            Spacer()
            
          }
        }
        .ignoresSafeArea()
      }
    }
    .customNavigationBar(
      centerView: {
        Text("\(index + 1)번째 문서")
          .font(.system(size: 15))
      },
      leftView: {
        HStack {
          Button(action: {
            if !navigationPath.isEmpty {
              navigationPath.removeLast()
            }
          }) {
            Image(systemName: "chevron.left")
              .resizable()
              .scaledToFit()
              .foregroundStyle(Color(hex: "494949"))
              .frame(height: 22)
          }
          .padding(.trailing, 20)
          Button(action: {
            
          }) {
            Image(systemName: "magnifyingglass")
              .resizable()
              .scaledToFit()
              .foregroundStyle(Color(hex: "494949"))
              .frame(height: 22)
          }
        }
      },
      rightView: {
        Picker("", selection: $selectedMode) {
          ForEach(mode, id: \.self) {
            Text($0)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 158)
        .background(Color(hex: "CDD0E5"))
        .cornerRadius(9)
        .padding(10)
      }
    )
  }
}

#Preview {
  PDFView(
    index: 1,
    mode: ["원문 모드", "집중 모드"],
    navigationPath: .constant(NavigationPath()))
}
