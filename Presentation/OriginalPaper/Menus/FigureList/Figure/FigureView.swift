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
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
    let onSelect: (UUID, String, PDFDocument, String) -> Void
    
    var body: some View {
        ZStack {
            Color.list
            
            VStack(spacing: 0) {
                switch focusFigureViewModel.figureStatus {
                case .beforeStart:
                    FigureBeforeStartView()
                    
                case .networkDisconnection:
                    FigureNetworkDisconnectionView()
                    
                case .loading:
                    Text("Figure와 Table이 있으면,\n여기에 표시됩니다")
                        .multilineTextAlignment(.center)
                        .reazyFont(.body3)
                        .foregroundStyle(.gray600)
                    
                case .empty, .complete:
                    FigureCompleteView(onSelect: onSelect)
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


/// Figure 추출 전 뷰
private struct FigureBeforeStartView: View {
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
    var body: some View {
        Text("Figure와 Table을 자동추출해서\n필요할 때 꺼내볼 수 있어요")
            .reazyFont(.body3)
            .foregroundStyle(.gray600)
            .multilineTextAlignment(.center)
        
        Button {
            focusFigureViewModel.downloadFocusFigure()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(.gray300)
                    .frame(width: 85, height: 32)
                
                Text("추출 시작")
                    .reazyFont(.button4)
                    .foregroundStyle(.primary1)
            }
        }
        .padding(.top, 8)
    }
}


/// Figure 네트워크 연결이 안되어 있을 때 뷰
private struct FigureNetworkDisconnectionView: View {
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Figure와 Table을 불러오기 위해\n네트워크 연결이 필요합니다.")
                .multilineTextAlignment(.center)
                .reazyFont(.body3)
                .foregroundStyle(.gray600)
            
            Button {
                focusFigureViewModel.downloadFocusFigure()
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
    }
}

/// Figure 추출 완료 뷰
private struct FigureCompleteView: View {
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    
    @State private var scrollToIndex: Int? = nil
    
    let onSelect: (UUID, String, PDFDocument, String) -> Void
    
    var body : some View {
        ZStack {
            if !focusFigureViewModel.figures.isEmpty {
                HStack(spacing: 0) {
                    Button(action: {
                        if let figure = focusFigureViewModel.figures.first {
                            guard let document = focusFigureViewModel.setFigureDocument(for: 0) else {
                                print("Failed to set figure document.")
                                return
                            }
                            let head = figure.head
                            let documentID = figure.id
                            let id = figure.uuid
                            
                            let newFigure = DroppedFigure(
                                id: id,
                                documentID: documentID,
                                document: document,
                                head: head,
                                isSelected: true,
                                viewOffset: CGSize(width: 0, height: 0),
                                lastOffset: CGSize(width: 0, height: 0),
                                viewWidth: 300,
                                isInSplitMode: true,
                                isFigure: true
                            )
                            floatingViewModel.droppedFigures.append(newFigure)
                            
                            floatingViewModel.isFigure = true
                            floatingViewModel.selectedFigureCellID = id
                            floatingViewModel.setSplitDocument(at: 0, uuid: id)
                        }
                    }) {
                        Image(.dualwindow)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 19)
                            .foregroundStyle(.primary1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // TODO: - 다중 선택 구현
                        /// Ver.2.0.1 구현 예정
                    }) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.clear)
                    }
                }
            }
            
            HStack(spacing: 0) {
                Spacer()
                
                Text("Fig & Table")
                    .reazyFont(.body1)
                    .foregroundStyle(.gray800)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 15)
        .padding(.bottom, 24)

        if focusFigureViewModel.figures.isEmpty {
            VStack(spacing: 0) {
                Spacer()
                Text("Figure와 Table이 있으면,\n여기에 표시됩니다")
                    .multilineTextAlignment(.center)
                    .reazyFont(.body3)
                    .foregroundStyle(.gray600)
                Spacer()
            }
        } else {
            // ScrollViewReader로 자동 스크롤 구현
            ScrollViewReader { proxy in
                List {
                    ForEach(focusFigureViewModel.figures, id: \.self) { item in
                        let id = item.uuid
                        FigureCell(id: id, onSelect: onSelect)
                            .listRowBackground(Color.list)
                            .padding(.bottom, 21)
                            .listRowSeparator(.hidden)
                            .id(id)
                    }
                }
                .listStyle(.plain)
                .padding(.horizontal, 10)
                .onChange(of: scrollToIndex) { _, newValue in
                    if let index = newValue, index < focusFigureViewModel.figures.count {
                        let id = focusFigureViewModel.figures[index].uuid // `uuid`를 사용
                        DispatchQueue.main.async {
                            withAnimation {
                                // 자동 스크롤
                                proxy.scrollTo(id, anchor: .top)
                                print(id)
                            }
                        }
                    }
                }
            }
            .background(.list)
        }
        
        VStack(spacing: 0){
            Button(action: {
                focusFigureViewModel.isCaptureMode.toggle()
                if focusFigureViewModel.isCaptureMode {
                    mainPDFViewModel.pdfDrawer.selectedStorage = .figure
                    mainPDFViewModel.pdfDrawer.drawingTool = .lasso
                    mainPDFViewModel.toolMode = .lasso
                } else {
                    mainPDFViewModel.toolMode = .none
                    mainPDFViewModel.pdfDrawer.drawingTool = .none
                    mainPDFViewModel.pdfDrawer.endCaptureMode()
                }
                mainPDFViewModel.selectedButton = nil
            }) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(!focusFigureViewModel.isCaptureMode ? .gray300 : .point4)
                        .frame(width: 212, height: 40)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    if !focusFigureViewModel.isCaptureMode {
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14)
                            .foregroundStyle(.primary1)
                            .padding(.top, 13)
                    } else {
                        Text("취소")
                            .reazyFont(.text1)
                            .foregroundStyle(.gray100)
                            .padding(.top, 11)
                    }
                }
                .frame(height: 80)
            }
            .frame(maxWidth: .infinity, maxHeight: 80)
        }
        .frame(maxWidth: .infinity, maxHeight: 80)
        .background(.gray100)
        // 원문보기 페이지 변경시 자동 스크롤
        .onReceive(focusFigureViewModel.$changedPageNumber) { num in
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
}
