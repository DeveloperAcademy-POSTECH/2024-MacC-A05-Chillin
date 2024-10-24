//
//  FigureView.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import Foundation
import PDFKit
import Combine

// MARK: - Lucid : Figure 뷰
struct FigureView: View {
    
    @EnvironmentObject var originalViewModel: OriginalViewModel
    @State private var scrollToIndex: Int? = nil
    @State private var cancellables = Set<AnyCancellable>()
    var onSelect: (PDFDocument, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if originalViewModel.figureAnnotations.isEmpty {
                Text("이미지가 없습니다.")
            } else {
                Text("피규어를 꺼내서 창에 띄울 수 있어요")
                    .reazyFont(.text2)
                    .foregroundStyle(.gray600)
                    .padding(.vertical, 24)
            }
            
            ScrollViewReader { proxy in                    // ScrollViewReader로 자동 스크롤 구현
                List {
                    ForEach(0..<originalViewModel.figureAnnotations.count, id: \.self) { index in
                        FigureCell(index: index, onSelect: onSelect)
                            .padding(.bottom, 21)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .onChange(of: scrollToIndex) { index in
                    if let index = index {
                        withAnimation {
                            proxy.scrollTo(index, anchor: .top)     // 자동 스크롤 구현
                        }
                    }
                }
            }
        }
        .onAppear {
            setupBindings()                                // 바인딩 설정
        }
    }
    
    // Combine 바인딩 설정
    private func setupBindings() {
        originalViewModel.$changedPageNumber
            .sink { num in
                // 페이지 변경시 자동 스크롤
                let pageCount = originalViewModel.figureAnnotations.count
                
                var foundIndex: Int? = nil
                
                // num과 같은 이미지 page 찾기
                for index in 0..<pageCount {
                    if originalViewModel.figureAnnotations[index].page == num {
                        foundIndex = index
                        break
                    }
                }
                
                // num과 같은 page가 있는 경우
                if let index = foundIndex {
                    scrollToIndex = index+1                 // 해당 인덱스로 스크롤
                } else {
                    // num과 같은 page가 없는 경우, num보다 큰 첫 번째 page 찾기
                    for index in 0..<pageCount {
                        if originalViewModel.figureAnnotations[index].page > num {
                            scrollToIndex = index           // 해당 인덱스로 스크롤
                            break
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}
