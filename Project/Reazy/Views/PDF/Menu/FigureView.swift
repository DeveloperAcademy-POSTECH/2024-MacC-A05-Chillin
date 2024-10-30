//
//  FigureView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import PDFKit

// MARK: - Lucid : Figure 뷰
struct FigureView: View {
    
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
  
    @State private var scrollToIndex: Int? = nil
    let onSelect: (String, PDFDocument, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if mainPDFViewModel.figureAnnotations.isEmpty {
                Text("이미지가 없습니다.")
            } else {
                Text("피규어를 꺼내서 창에 띄울 수 있어요")
                    .reazyFont(.text2)
                    .foregroundStyle(.gray600)
                    .padding(.vertical, 24)
            }
            
            // ScrollViewReader로 자동 스크롤 구현
            ScrollViewReader { proxy in
                List {
                    ForEach(0..<mainPDFViewModel.figureAnnotations.count, id: \.self) { index in
                        FigureCell(index: index, onSelect: onSelect)
                            .padding(.bottom, 21)
                            .listRowSeparator(.hidden)
                    }
                }
                .padding(.horizontal, 10)
                .listStyle(.plain)
                .onChange(of: scrollToIndex) { _, newValue in
                    if let index = newValue {
                        withAnimation {
                            // 자동 스크롤
                            proxy.scrollTo(index, anchor: .top)
                        }
                    }
                }
            }
        }
        // 원문보기 페이지 변경시 자동 스크롤
        .onChange(of: mainPDFViewModel.changedPageNumber) { _, newValue in
            
            let pageCount = mainPDFViewModel.figureAnnotations.count
            var foundIndex: Int? = nil
            
            // num과 같은 이미지 page 찾기
            for index in 0..<pageCount {
                if mainPDFViewModel.figureAnnotations[index].page == newValue {
                    foundIndex = index
                    break
                }
            }
            
            // num과 같은 page가 있는 경우
            if let index = foundIndex {
                scrollToIndex = index + 1                    // 해당 인덱스로 스크롤
            } else {
                // num과 같은 page가 없는 경우, num보다 큰 첫 번째 page 찾기
                for index in 0..<pageCount {
                    if mainPDFViewModel.figureAnnotations[index].page > newValue {
                        scrollToIndex = index                // 해당 인덱스로 스크롤
                        break
                    }
                }
            }
        }
    }
}
