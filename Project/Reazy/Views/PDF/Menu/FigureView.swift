//
//  FigureView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import Foundation
import PDFKit

// MARK: - Lucid : Figure 뷰
struct FigureView: View {
    
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    var onSelect: (PDFDocument, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if mainPDFViewModel.figureAnnotations.isEmpty {        // figureAnnotations가 비어있을 경우
                Text("이미지가 없습니다.")
            } else {
                Text("피규어를 꺼내서 창에 띄울 수 있어요")
                    .reazyFont(.text2)
                    .foregroundStyle(.gray600)
                    .padding(.vertical, 24)
            }
            
            List {
                ForEach(0..<mainPDFViewModel.figureAnnotations.count, id: \.self) { index in
                  FigureCell(index: index, onSelect: onSelect)
                        .padding(.bottom, 21)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
        }
    }
}
