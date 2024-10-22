//
//  FigureCell.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//


import SwiftUI
import PDFKit
import UniformTypeIdentifiers


// MARK: - Lucid : FigureView 커스텀 리스트 셀
struct PDFKitView: UIViewRepresentable {
  
  let document: PDFDocument
  
  // PDFView 생성 후 반환
  func makeUIView(context: Context) -> PDFView {
    let pdfView = PDFView()
    
    pdfView.autoScales = true       // PDF가 뷰에 맞춰서 스케일 조정
    pdfView.document = document
    pdfView.translatesAutoresizingMaskIntoConstraints = false
    pdfView.displayMode = .singlePageContinuous
    pdfView.pageShadowsEnabled = false
    pdfView.subviews.first!.backgroundColor = .white
    
    return pdfView
  }
  
  // 업데이트 메서드 (필요에 따라 사용)
  func updateUIView(_ uiView: PDFView, context: Context) {
    // 필요에 따라 업데이트 사항이 있으면 이곳에서 처리
  }
}


struct FigureCell: View {
  
  @EnvironmentObject var originalViewModel: OriginalViewModel
  let index: Int
  
  var onSelect: (PDFDocument, String) -> Void
  
  @State private var aspectRatio: CGFloat = 1.0
  
  var body: some View {
    VStack(spacing: 0) {
      ZStack  {
        if let document = originalViewModel.setFigureDocument(for: index) {
          if let page = document.page(at: 0) {
            let pageRect = page.bounds(for: .mediaBox)
            let aspectRatio = pageRect.width / pageRect.height
            
            PDFKitView(document: document)
              .edgesIgnoringSafeArea(.all)        // 전체 화면에 맞추기
              .frame(width: 180, height: 180 / aspectRatio)
              .padding(8)
              .simultaneousGesture(
                TapGesture().onEnded {
                  let head = originalViewModel.figureAnnotations[index].head
                  print("FigureCell tapped. Sending document and head to onSelect.")
                  onSelect(document, head)
                }
              )
            
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color(hex: "#CDCFE1"), lineWidth: 1)
          }
        } else {
          Text("pdf 로드 실패 ")
        }
      }
      .padding(.bottom, 10)
      
      Text(originalViewModel.figureAnnotations[index].head)
        .reazyFont(.text2)
    }
  }
}

