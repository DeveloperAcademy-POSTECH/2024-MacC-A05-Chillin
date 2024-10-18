//
//  PDFView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

struct MainPDFView: View {
    
    @StateObject private var originalViewModel: OriginalViewModel = .init()
  
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
                // MARK: - 부리꺼 : 색상 적용 필요
                  .foregroundStyle(isSelected[index] ? Color(hex: "5F5DAA") : .clear)
                  .overlay (
                    Image(systemName: icons[index])
                      .resizable()
                      .scaledToFit()
                      .foregroundStyle(isSelected[index] ? .gray100 : .gray800)
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
                // MARK: - 부리꺼 : 색상 적용 필요
                  .foregroundStyle(isSelected[index] ? Color(hex: "5F5DAA") : .clear)
                  .overlay (
                    Text("Fig")
                      .font(.system(size: 14))
                      .foregroundStyle(isSelected[index] ? .gray100 : .gray800)
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
              .foregroundStyle(.gray800)
              .frame(height: 19)
          }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 30)
        .background(.primary3)
        
        HStack(spacing: 0) {
          Spacer()
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "text.bubble")
              .resizable()
              .scaledToFit()
              .foregroundStyle(.gray800)
              .frame(height: 19)
          }
          .padding(.trailing, 39)
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "character.bubble")
              .resizable()
              .scaledToFit()
              .foregroundStyle(.gray800)
              .frame(height: 19)
          }
          .padding(.trailing, 39)
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "pencil.tip.crop.circle")
              .resizable()
              .scaledToFit()
              .foregroundStyle(.gray800)
              .frame(height: 19)
          }
          .padding(.trailing, 39)
          
          Button(action: {
            // 버튼 액션 추가
          }) {
            Image(systemName: "square.dashed")
              .resizable()
              .scaledToFit()
              .foregroundStyle(.gray800)
              .frame(height: 19)
          }
          
          Spacer()
        }
        .background(.clear)
      }
      
      Divider()
        .foregroundStyle(Color(hex: "CCCEE1"))
      
      GeometryReader { geometry in
        ZStack {
            if selectedMode == "원문 모드" {
                OriginalView()
                    .environmentObject(originalViewModel)
            }
            else if selectedMode == "집중 모드" {
                ConcentrateView()
                    .environmentObject(originalViewModel)
            }
          
          // MARK: - 모아보기 창
          HStack(spacing: 0){
            if isSelected[0] {
                TableView(originalViewModel: originalViewModel)
                .environmentObject(originalViewModel)
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
          .reazyFont(.h3)
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
              .foregroundStyle(.gray800)
              .frame(height: 22)
          }
          .padding(.trailing, 20)
          Button(action: {
            
          }) {
            Image(systemName: "magnifyingglass")
              .resizable()
              .scaledToFit()
              .foregroundStyle(.gray800)
              .frame(height: 22)
          }
        }
      },
      rightView: {
        Picker("", selection: $selectedMode) {
          ForEach(mode, id: \.self) {
            Text($0)
              .reazyFont(.button4)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 158)
        .background(.gray500)
        .cornerRadius(9)
        .padding(10)
      }
    )
  }
}

//#Preview {
//  MainPDFView(
//    index: 1,
//    mode: ["원문 모드", "집중 모드"],
//    navigationPath: .constant(NavigationPath()))
//}
