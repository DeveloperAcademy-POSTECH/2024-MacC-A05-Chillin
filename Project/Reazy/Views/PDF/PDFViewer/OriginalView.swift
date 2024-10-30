//
//  OriginalView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI
import PencilKit

// MARK: - 무니꺼 : 원문 모드 뷰
struct OriginalView: View {
    @EnvironmentObject private var viewModel: MainPDFViewModel
    @State var canvas = PKCanvasView() // 캔버스 도화지
    @State var isPenciled: Bool = true // 도구선택유무
    
    @State var colors: [Color] = [.black] // 추후 색깔 추가
    @State var selectedColor: Color = .black // 디폴트 검정펜
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OriginalViewControllerRepresent() // PDF 뷰를 표시
            }
            .onTapGesture {
                // 터치 시 말풍선 뷰를 숨기는 처리 추가
                viewModel.updateBubbleView(selectedText: "", bubblePosition: .zero)
            }
            // 번역에 사용되는 말풍선뷰
            if viewModel.isTranslateMode {
                if viewModel.isBubbleViewVisible {
                    if #available(iOS 18.0, *) {
                        BubbleView(selectedText: $viewModel.selectedText, bubblePosition: $viewModel.bubbleViewPosition)

                    } else {
                        // TODO : 이전 버전 처리
                    }
                }
            }
            // 드로잉 & 지우개에 사용되는 캔버스뷰 -> 이건 미리 깔아두고 그리기 모드만 on 해야할 듯
            if viewModel.isPencilMode || viewModel.isEraserMode { // 둘 중 하나라도 활성화 중이면
                CanvasView(canvas: $canvas, isPencilMode: $viewModel.isPencilMode, color: $selectedColor)
                    .allowsHitTesting(viewModel.isPencilMode ? true : false)
            }
        }
        .onChange(of: viewModel.selectedText) { _, newValue in
            viewModel.updateBubbleView(selectedText: newValue, bubblePosition: viewModel.bubbleViewPosition)
        }
    }
}
