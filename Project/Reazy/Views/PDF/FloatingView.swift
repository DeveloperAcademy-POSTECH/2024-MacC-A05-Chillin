//
//  FloatingView.swift
//  Reazy
//
//  Created by 유지수 on 10/20/24.
//

import SwiftUI
import PDFKit

struct FloatingView: View {
  
  let document: PDFDocument
  let head: String
  @Binding var isSelected: Bool
  @Binding var viewOffset: CGSize
  @Binding var viewWidth: CGFloat
  
  @State private var aspectRatio: CGFloat = 1.0
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Button(action: {
          
        }, label: {
          Image(systemName: "rectangle.split.2x1")
            .font(.system(size: 16))
            .foregroundStyle(.gray600)
        })
        
        Spacer()
        
        // TODO: - 피그마 반영 시 수정 필요
        Text(head)
          .reazyFont(.button5)
          .foregroundStyle(.gray800)
        
        Spacer()
        
        Button(action: {
          isSelected.toggle()
        }, label: {
          Image(systemName: "xmark")
            .font(.system(size: 16))
            .foregroundStyle(.gray600)
        })
      }
      .padding(.bottom, 11)
      .padding(.horizontal, 16)
      .frame(height: 40)
      
      Divider()
      
      PDFKitView(document: document, isScrollEnabled: true)
        .frame(width: viewWidth - 36, height: (viewWidth - 36) / aspectRatio)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    .frame(width: viewWidth)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(.white)
    )
    .overlay(
      Image(systemName: "righttriangle.fill")
        .frame(width: 80, height: 80)
        .offset(x: 20, y: 20)
        .foregroundStyle(.gray600)
        .contentShape(Rectangle())
        .gesture(
          DragGesture()
            .onChanged { value in
              // 최대 크기 제한 850 + 최소 크기 제한 300
              let newWidth = max(min(viewWidth + value.translation.width, 850), 300)
              self.viewWidth = newWidth
            }
        )
        .padding(.leading, 100)
        .padding(.top, 100),
      alignment: .bottomTrailing
    )
    .offset(viewOffset)
    .onAppear {
      // PDF의 첫 번째 페이지 크기를 기준으로 비율 결정
      if let page = document.page(at: 0) {
        let pageRect = page.bounds(for: .mediaBox)
        self.aspectRatio = pageRect.width / pageRect.height
        self.viewWidth = pageRect.width
      }
    }
  }
}

#Preview {
  @Previewable @State var viewOffset: CGSize = .zero
  @Previewable @State var viewWidth: CGFloat = 500
  FloatingView(
    document: PDFDocument(),
    head: "Fig 3.1",
    isSelected: .constant(true),
    viewOffset: $viewOffset,
    viewWidth: $viewWidth
  )
}
