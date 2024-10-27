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
  
  @State private var droppedFigures: [(document: PDFDocument, head: String, isSelected: Bool, viewOffset: CGSize, lastOffset: CGSize, viewWidth: CGFloat)] = []
  @State private var topmostIndex: Int? = nil
  
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
                  } else {
                    selectedButton = btn
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
                  
                  FigureView(onSelect: { document, head in
                    print("Document selected: \(document), head: \(head)")
                    
                    droppedFigures.append(
                      (
                        document: document,
                        head: head,
                        isSelected: true,
                        viewOffset: CGSize(width: 0, height: 0),
                        lastOffset: CGSize(width: 0, height: 0),
                        viewWidth: 300
                      )
                    )
                    print("Current droppedFigures count: \(droppedFigures.count)")
                  })
                  .environmentObject(mainPDFViewModel)
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
        
        ForEach(droppedFigures.indices, id: \.self) { index in
          let droppedFigure = droppedFigures[index]
          let isTopmost = (topmostIndex == index)
          
          if droppedFigure.isSelected {
            FloatingView(
              document: droppedFigure.document,
              head: droppedFigure.head,
              isSelected: Binding(
                get: { droppedFigure.isSelected },
                set: { newValue in
                  droppedFigures[index].isSelected = newValue
                  if newValue {
                    topmostIndex = index
                  }
                }
              ),
              viewOffset: Binding(
                get: { droppedFigures[index].viewOffset },
                set: { droppedFigures[index].viewOffset = $0 }
              ),
              viewWidth: Binding(
                get: { droppedFigures[index].viewWidth },
                set: { droppedFigures[index].viewWidth = $0 }
              )
            )
            .aspectRatio(contentMode: .fit)
            .shadow(
              color: Color(hex: "4D4A97").opacity(0.20),
              radius: 12,
              x: 0,
              y: 2)
            .padding(4.5)
            .zIndex(isTopmost ? 1 : 0)
            .gesture(
              DragGesture()
                .onChanged { value in
                  let newOffset = CGSize(
                    width: droppedFigures[index].lastOffset.width + value.translation.width,
                    height: droppedFigures[index].lastOffset.height + value.translation.height
                  )
                  
                  let maxX = geometry.size.width / 2 - droppedFigures[index].viewWidth / 2 + 200
                  let minX = -(geometry.size.width / 2 - droppedFigures[index].viewWidth / 2) - 200
                  let maxY = geometry.size.height / 2 - 150 + 200
                  let minY = -(geometry.size.height / 2 - 150) - 200
                  
                  droppedFigures[index].viewOffset = CGSize(
                    width: min(max(newOffset.width, minX), maxX),
                    height: min(max(newOffset.height, minY), maxY)
                  )
                }
                .onEnded { _ in
                  droppedFigures[index].lastOffset = droppedFigures[index].viewOffset
                }
            )
            .onTapGesture {
              topmostIndex = index
            }
          }
        }
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
