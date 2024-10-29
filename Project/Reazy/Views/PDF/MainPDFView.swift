//
//  PDFView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct MainPDFView: View {
  
  @StateObject private var mainPDFViewModel: MainPDFViewModel = .init()
  @StateObject private var floatingViewModel: FloatingViewModel = .init()
  
  @State private var selectedButton: WriteButton? = nil
  @State private var selectedColor: HighlightColors = .yellow
  
  
  // 모드 구분
  @State private var selectedMode = "원문 모드"
  var mode = ["원문 모드", "집중 모드"]
  @Namespace private var animationNamespace
  
  @State private var selectedIndex: Int = 1
  @State private var isFigSelected: Bool = false
  
  @Binding var navigationPath: NavigationPath
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        VStack(spacing: 0) {
          Divider()
            .foregroundStyle(Color(hex: "CCCEE1"))
          
          ZStack {
            HStack(spacing: 0) {
              Button(action: {
                if selectedIndex == 1 {
                  selectedIndex = 0
                } else {
                  selectedIndex = 1
                }
              }) {
                RoundedRectangle(cornerRadius: 6)
                  .frame(width: 26, height: 26)
                  .foregroundStyle(selectedIndex == 1 ? .primary1 : .clear)
                  .overlay (
                    Image(systemName: "list.bullet")
                      .resizable()
                      .scaledToFit()
                      .foregroundStyle(selectedIndex == 1 ? .gray100 : .gray800)
                      .frame(width: 18)
                  )
              }
              .padding(.trailing, 36)
              
              Button(action: {
                if selectedIndex == 2 {
                  selectedIndex = 0
                } else {
                  selectedIndex = 2
                }
              }) {
                RoundedRectangle(cornerRadius: 6)
                  .frame(width: 26, height: 26)
                  .foregroundStyle(selectedIndex == 2 ? .primary1 : .clear)
                  .overlay (
                    Image(systemName: "rectangle.grid.1x2")
                      .resizable()
                      .scaledToFit()
                      .foregroundStyle(selectedIndex == 2 ? .gray100 : .gray800)
                      .frame(width: 18)
                  )
              }
              
              Spacer()
              
              Button(action: {
                isFigSelected.toggle()
              }) {
                RoundedRectangle(cornerRadius: 6)
                  .frame(width: 26, height: 26)
                // MARK: - 부리꺼 : 색상 적용 필요
                  .foregroundStyle(isFigSelected ? Color(hex: "5F5DAA") : .clear)
                  .overlay (
                    Text("Fig")
                      .font(.system(size: 14))
                      .foregroundStyle(isFigSelected ? .gray100 : .gray800)
                  )
              }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 30)
            .background(.primary3)
            
            HStack(spacing: 0) {
              Spacer()
              
              ForEach(WriteButton.allCases, id: \.self) { btn in
                // 조건부 Padding값 조정
                let trailingPadding: CGFloat = {
                  if selectedButton == .highlight && btn == .highlight {
                    return .zero
                  } else if btn == .translate {
                    return .zero
                  } else {
                    return 32
                  }
                }()
                
                // [Comment], [Highlight], [Pencil], [Eraser], [Translate] 버튼
                WriteViewButton(button: $selectedButton, HighlightColors: $selectedColor, buttonOwner: btn) {
                  // MARK: - 작성 관련 버튼 action 입력
                  /// 위의 다섯 개 버튼의 action 로직은 이곳에 입력해 주세요
                  if selectedButton == btn {
                    selectedButton = nil
                    mainPDFViewModel.isTranslateMode = false
                  } else {
                    selectedButton = btn
                    
                    // 번역 버튼
                    if selectedButton == .translate {
                      mainPDFViewModel.isTranslateMode = true // translation mode
                      NotificationCenter.default.post(name: .translateModeActivated, object: nil)
                      print("번역모드 on")
                    } else {
                      mainPDFViewModel.isTranslateMode = false
                    }
                    
                  }
                }
                .padding(.trailing, trailingPadding)
                
                // Highlight 버튼이 선택될 경우 색상을 선택
                if selectedButton == .highlight && btn == .highlight {
                  highlightColorSelector()
                }
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
                  .environmentObject(mainPDFViewModel)
              }
              else if selectedMode == "집중 모드" {
                ConcentrateView()
                  .environmentObject(mainPDFViewModel)
              }
              
              HStack(spacing: 0){
                if selectedIndex == 1 {
                  TableView()
                    .environmentObject(mainPDFViewModel)
                    .background(.white)
                    .frame(width: geometry.size.width * 0.22)
                  
                  Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color(hex: "CCCEE1"))
                } else if selectedIndex == 2 {
                  PageView()
                    .environmentObject(mainPDFViewModel)
                    .background(.white)
                    .frame(width: geometry.size.width * 0.22)
                  
                  Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color(hex: "CCCEE1"))
                } else {
                  EmptyView()
                }
                
                Spacer()
                
                if isFigSelected {
                  Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color(hex: "CCCEE1"))
                  
                  FigureView(onSelect: { documentID, document, head in
                    floatingViewModel.toggleSelection(for: documentID, document: document, head: head)
                  })
                  .environmentObject(mainPDFViewModel)
                  .environmentObject(floatingViewModel)
                  .background(.white)
                  .frame(width: geometry.size.width * 0.22)
                }
              }
            }
            .ignoresSafeArea()
          }
        }
        .customNavigationBar(
          centerView: {
            // MARK: - 모델 생성 시 수정 필요
            Text("A review of the global climate change impacts, adaptation, and sustainable mitigation measures")
              .reazyFont(.h3)
              .frame(width: 342)
              .lineLimit(1)
          },
          leftView: {
            HStack {
              Button(action: {
                if !navigationPath.isEmpty {
                  navigationPath.removeLast()
                }
              }) {
                Image(systemName: "chevron.left")
                  .foregroundStyle(.gray800)
                  .font(.system(size: 16))
              }
              .padding(.trailing, 20)
              Button(action: {
                
              }) {
                Image(systemName: "magnifyingglass")
                  .foregroundStyle(.gray800)
                  .font(.system(size: 16))
              }
            }
          },
          rightView: {
            HStack(spacing: 0) {
              Button(action: {
                // TODO: - 뒤로 가기 버튼 활성화 필요
              }, label: {
                Image(systemName: "arrow.uturn.left")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(Color(hex: "BABCCF"))
                  .frame(height: 19)
              })
              .padding(.trailing, 18)
              Button(action: {
                // TODO: - 앞으로 가기 버튼 활성화 필요
              }, label: {
                Image(systemName: "arrow.uturn.right")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(Color(hex: "BABCCF"))
                  .frame(height: 19)
              })
              .padding(.trailing, 24)
              
              // Custom segmented picker
              HStack(spacing: 0) {
                ForEach(mode, id: \.self) { item in
                  Text(item)
                    .reazyFont(selectedMode == item ? .button4 : .button5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(
                      ZStack {
                        if selectedMode == item {
                          RoundedRectangle(cornerRadius: 7)
                            .fill(.gray100)
                            .matchedGeometryEffect(id: "underline", in: animationNamespace)
                        }
                      }
                    )
                    .foregroundColor(selectedMode == item ? .gray900 : .gray600)
                    .onTapGesture {
                      withAnimation(.spring()) {
                        selectedMode = item
                      }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
              }
              .background(.gray500)
              .cornerRadius(9)
            }
          }
        )
        
        // MARK: - Floating 뷰
        FloatingViewsContainer(geometry: geometry)
          .environmentObject(floatingViewModel)
      }
    }
  }
  
  @ViewBuilder
  private func highlightColorSelector() -> some View {
    Rectangle()
      .frame(width: 1, height: 19)
      .foregroundStyle(.primary4)
      .padding(.leading, 24)
      .padding(.trailing, 17)
    
    ForEach(HighlightColors.allCases, id: \.self) { color in
      ColorButton(button: $selectedColor, buttonOwner: color) {
        // MARK: - 펜 색상 변경 action 입력
        /// 펜 색상을 변경할 경우, 변경된 색상을 입력하는 로직은 여기에 추가
        selectedColor = color
      }
      .padding(.trailing, color == .blue ? .zero : 18)
    }
    
    Rectangle()
      .frame(width: 1, height: 19)
      .foregroundStyle(.primary4)
      .padding(.leading, 24)
      .padding(.trailing, 17)
  }
}
