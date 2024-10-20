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
  @State private var isDropTargeted: Bool = false
  @State private var droppedFigures: [(document: PDFDocument, head: String, isSelected: Bool, viewOffset: CGSize, lastOffset: CGSize, viewWidth: CGFloat)] = []
  @State private var topmostIndex: Int? = nil
  
  // 문서 선택 확인을 위한 인덱스
  let index: Int
  
  // 모드 구분
  @State private var selectedMode = "원문 모드"
  var mode = ["원문 모드", "집중 모드"]
  
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
              // MARK: - 왼쪽 상단 버튼 3개
              /// 버튼 하나가 글자로 이루어져 있어서 분리
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
                // 버튼 액션 추가
              }) {
                Image(systemName: "link.badge.plus")
                  .resizable()
                  .scaledToFit()
                  .foregroundStyle(.gray800)
                  .frame(height: 19)
              }
              .padding(.trailing, 36)
              
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
                  
                  FigureView()
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
              color: Color(hex: "4D4A97").opacity(0.06),
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
      .onDrop(of: [UTType.pdf.identifier], isTargeted: $isDropTargeted) { providers, location in
        handleDrop(providers: providers, at: location, in: geometry)
      }
    }
  }
  
  /// PDF 문서 드롭
  func handleDrop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
    let geometryWidth = geometry.size.width
    let geometryHeight = geometry.size.height
    let adjustedLocation = CGPoint(
      x: location.x - geometry.frame(in: .global).minX,
      y: location.y - geometry.frame(in: .global).minY
    )
    
    for provider in providers {
      
      let head = provider.suggestedName ?? ""
      
      provider.loadDataRepresentation(forTypeIdentifier: UTType.pdf.identifier) { data, error in
        if let data = data, let pdfDocument = PDFDocument(data: data) {
          DispatchQueue.main.async {
            withAnimation(.none) {
              droppedFigures.append(
                (
                  document: pdfDocument,
                  head: head,
                  isSelected: true,
                  viewOffset: CGSize(
                    width: adjustedLocation.x - geometryWidth / 2,
                    height: adjustedLocation.y - geometryHeight / 2
                  ),
                  lastOffset: CGSize(
                    width: adjustedLocation.x - geometryWidth / 2,
                    height: adjustedLocation.y - geometryHeight / 2
                  ),
                  viewWidth: 300
                )
              )
            }
          }
        } else if let error = error {
          print("Error loading PDF: \(error.localizedDescription)")
        }
      }
    }
    return true
  }
}
