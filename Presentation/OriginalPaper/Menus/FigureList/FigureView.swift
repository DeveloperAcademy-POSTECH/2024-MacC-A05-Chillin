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
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
    @State private var scrollToIndex: Int? = nil
    
    let onSelect: (String, PDFDocument, String) -> Void
    
    var body: some View {
        ZStack {
            Color.list
            VStack(spacing: 0) {
                // TODO: 처음 들어오는지 여부 판단 필요
                
                switch focusFigureViewModel.figureStatus {
                case .networkDisconnection:
                    VStack(spacing: 12) {
                        Text("Figure와 Table을 불러오기 위해\n네트워크 연결이 필요합니다.")
                            .multilineTextAlignment(.center)
                            .reazyFont(.body3)
                            .foregroundStyle(.gray600)
                        
                        Button {
                            focusFigureViewModel.fetchAnnotations()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .foregroundStyle(.gray200)
                                    .frame(width: 72, height: 28)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(lineWidth: 1)
                                    .foregroundStyle(.gray500)
                                    .frame(width: 72, height: 28)
                                
                                Text("다시 시도")
                                    .reazyFont(.body3)
                                    .foregroundStyle(.gray600)
                            }
                        }
                    }
                case .loading:
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding(.bottom, 16)
                    
                    Text("Figure와 Table을 불러오는 중입니다")
                        .multilineTextAlignment(.center)
                        .reazyFont(.body3)
                        .foregroundStyle(.gray600)
                case .empty:
                    Text("Fig와 Table이 있으면,\n여기에 표시됩니다")
                        .multilineTextAlignment(.center)
                        .reazyFont(.body3)
                        .foregroundStyle(.gray600)
                case .complete:
                    HStack(spacing: 0) {
                        Button(action: {
                            // TODO: - splitView 진입
                            // 선택된 Floating이 없을 경우 반드시 첫 figure 선택
                        }) {
                            Image(.dualwindow)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 19)
                                .foregroundStyle(.primary1)
                        }
                        
                        Spacer()
                        
                        Text("Fig & Table")
                            .reazyFont(.body1)
                            .foregroundStyle(.gray800)
                        
                        Spacer()
                        
                        Button(action: {
                            // TODO: - 다중 선택 구현
                        }) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 16))
                                .foregroundStyle(.primary1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 15)
                    .padding(.bottom, 24)
 
                    
                    // ScrollViewReader로 자동 스크롤 구현
                    ScrollViewReader { proxy in
                        List {
                            ForEach(focusFigureViewModel.figures, id: \.self) { item in
                                let id = item.uuid
                                FigureCell(id: id, onSelect: onSelect)
                                    .padding(.bottom, 21)
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .padding(.horizontal, 10)
                        .listStyle(.plain)
                        .onChange(of: scrollToIndex) { _, newValue in
                            if let index = newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        // 자동 스크롤
                                        proxy.scrollTo(index, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                    VStack(spacing: 0){
                        Button(action: {
                            focusFigureViewModel.isCaptureMode.toggle()
                            if focusFigureViewModel.isCaptureMode {
                                mainPDFViewModel.drawingToolMode = .lasso
                                mainPDFViewModel.toolMode = .lasso
                                mainPDFViewModel.updateDrawingTool()
                            } else {
                                mainPDFViewModel.toolMode = .none
                                mainPDFViewModel.updateDrawingTool()
                                mainPDFViewModel.drawingToolMode = .none
                                mainPDFViewModel.pdfDrawer.endCaptureMode()
                            }
                        }) {
                            ZStack(alignment: .center) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.gray300)
                                    .frame(width: 212, height: 40)
                                    .padding(.horizontal, 20)
                                
                                if !focusFigureViewModel.isCaptureMode {
                                    Image(systemName: "plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14)
                                        .foregroundStyle(.primary1)
                                } else {
                                    Text("취소")
                                        .reazyFont(.text1)
                                        .foregroundStyle(.primary1)
                                }
                            }
                            .frame(height: 76)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 76)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 76)
                    .background(.gray100)
                }
            }
        }
        // 원문보기 페이지 변경시 자동 스크롤
        .onReceive(focusFigureViewModel.$changedPageNumber) { num in
            guard let num = num else { return }
            updateScrollIndex(for: num)
        }
    }
    
    private func updateScrollIndex(for pageNumber: Int) {
        
        let pageCount = focusFigureViewModel.figures.count
        var foundIndex: Int? = nil
        
        for index in 0..<pageCount {
            if focusFigureViewModel.figures[index].page == pageNumber {
                foundIndex = index
                break
            }
        }
        
        if let index = foundIndex {
            scrollToIndex = index + 1
        } else {
            for index in 0..<pageCount {
                if focusFigureViewModel.figures[index].page > pageNumber {
                    scrollToIndex = index
                    break
                }
            }
        }
    }
    
    enum FigureStatus {
        case networkDisconnection
        case loading
        case empty
        case complete
    }
}
