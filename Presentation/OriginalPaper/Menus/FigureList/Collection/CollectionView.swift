//
//  CollectionView.swift
//  Reazy
//
//  Created by 유지수 on 11/27/24.
//

import SwiftUI
import PDFKit

struct CollectionView: View {
    
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    
    @State private var scrollToIndex: Int? = nil
    
    let onSelect: (UUID, String, PDFDocument, String) -> Void
    
    var body: some View {
        ZStack {
            Color.list
            VStack(spacing: 0) {
                ZStack {
                    if !focusFigureViewModel.collections.isEmpty {
                        HStack(spacing: 0) {
                            Button(action: {
                                if let figure = focusFigureViewModel.collections.first {
                                    let document = focusFigureViewModel.setCollectionDocument(for: 0)!
                                    let head = figure.head
                                    let documentID = figure.id
                                    let id = figure.uuid
                                    
                                    let newCollection = DroppedFigure(
                                        id: id,
                                        documentID: documentID,
                                        document: document,
                                        head: head,
                                        isSelected: true,
                                        viewOffset: CGSize(width: 0, height: 0),
                                        lastOffset: CGSize(width: 0, height: 0),
                                        viewWidth: 300,
                                        isInSplitMode: true,
                                        isFigure: false
                                    )
                                    floatingViewModel.droppedFigures.append(newCollection)
                                    
                                    floatingViewModel.isFigure = false
                                    floatingViewModel.selectedFigureCellID = id
                                    floatingViewModel.setSplitDocument(at: 0, uuid: id)
                                }
                            }) {
                                Image(.dualwindow)
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 19, height: 18)
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
                        
                        Text("모아보기")
                            .reazyFont(.body1)
                            .foregroundStyle(.gray800)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 15)
                .padding(.bottom, 24)
                
                if focusFigureViewModel.collections.isEmpty {
                    VStack(spacing: 0) {
                        Spacer()
                        Text("플로팅 창으로 띄운 영역을\n저장해 모아볼 수 있어요")
                            .multilineTextAlignment(.center)
                            .reazyFont(.body3)
                            .foregroundStyle(.gray600)
                        Spacer()
                    }
                } else {
                    // ScrollViewReader로 자동 스크롤 구현
                    ScrollViewReader { proxy in
                        List {
                            ForEach(focusFigureViewModel.collections, id: \.self) { item in
                                let id = item.uuid
                                CollectionCell(id: id, onSelect: onSelect)
                                    .padding(.bottom, 21)
                                    .listRowSeparator(.hidden)
                                    .id(id)
                            }
                        }
                        .padding(.horizontal, 10)
                        .listStyle(.plain)
                        .onChange(of: scrollToIndex) { _, newValue in
                            if let index = newValue, index < focusFigureViewModel.collections.count {
                                let id = focusFigureViewModel.collections[index].uuid // `uuid`를 사용
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
                }
                
                VStack(spacing: 0){
                    Button(action: {
                        focusFigureViewModel.isCaptureMode.toggle()
                        if focusFigureViewModel.isCaptureMode {
                            mainPDFViewModel.pdfDrawer.selectedStorage = .collection
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
            }
        }
        // 원문보기 페이지 변경시 자동 스크롤
        .onReceive(focusFigureViewModel.$changedPageNumber) { num in
            updateScrollIndex(for: num)
        }
    }
    
    private func updateScrollIndex(for pageNumber: Int) {
        
        let pageCount = focusFigureViewModel.collections.count
        var foundIndex: Int? = nil
        
        for index in 0..<pageCount {
            if focusFigureViewModel.collections[index].page == pageNumber {
                foundIndex = index
                break
            }
        }
        
        if let index = foundIndex {
            scrollToIndex = index + 1
        } else {
            for index in 0..<pageCount {
                if focusFigureViewModel.collections[index].page > pageNumber {
                    scrollToIndex = index
                    break
                }
            }
        }
    }
}
