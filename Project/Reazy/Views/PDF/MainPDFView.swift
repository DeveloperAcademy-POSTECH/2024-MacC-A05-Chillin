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
  
  @StateObject private var originalViewModel: OriginalViewModel = .init()
  @State private var droppedFigures: [(document: PDFDocument, head: String, isSelected: Bool, viewOffset: CGSize, lastOffset: CGSize, viewWidth: CGFloat)] = []
  @State private var topmostIndex: Int? = nil
  
  // 문서 선택 확인을 위한 인덱스
  let index: Int
  
  // 모드 구분
  @State private var selectedMode = "원문 모드"
  var mode = ["원문 모드", "집중 모드"]
  @Namespace private var animationNamespace
  
  // 모아보기 버튼 구분
  @State private var isSelected: [Bool] = [false, false]
  @State private var icons: [String] = ["list.bullet", "rectangle.grid.1x2"]
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
              ForEach(0..<isSelected.count, id: \.self) { index in
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
              
              Button(action: {
                // 버튼 액션 추가
              }) {
                Image(systemName: "text.bubble")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(.gray800)
                  .frame(height: 18)
              }
              .padding(.trailing, 39)
              
              Button(action: {
                // 버튼 액션 추가
              }) {
                Image(systemName: "highlighter")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(.gray800)
                  .frame(height: 18)
              }
              .padding(.trailing, 39)
              
              Button(action: {
                // 버튼 액션 추가
              }) {
                Image(systemName: "scribble")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(.gray800)
                  .frame(height: 18)
              }
              .padding(.trailing, 39)
              
              Button(action: {
                // 버튼 액션 추가
              }) {
                Image(systemName: "eraser")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(.gray800)
                  .frame(height: 18)
              }
              .padding(.trailing, 39)
              
              Button(action: {
                // 버튼 액션 추가
              }) {
                Image(systemName: "character.square")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(.gray800)
                  .frame(height: 18)
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
                  TableView()
                    .environmentObject(originalViewModel)
                    .background(.white)
                    .frame(width: geometry.size.width * 0.22)
                  
                  Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color(hex: "CCCEE1"))
                } else if isSelected[1] {
                  PageView()
                    .environmentObject(originalViewModel)
                    .background(.white)
                    .frame(width: geometry.size.width * 0.22)
                  
                  Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(Color(hex: "CCCEE1"))
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
                  .environmentObject(originalViewModel)
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
                            .matchedGeometryEffect(id: "underline", in: animationNamespace) // 애니메이션 효과
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
              .background(.gray500) // 전체 배경
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
}
