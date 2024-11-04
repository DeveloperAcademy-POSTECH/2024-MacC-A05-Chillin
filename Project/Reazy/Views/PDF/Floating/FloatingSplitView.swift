//
//  FloatingSplitView.swift
//  Reazy
//
//  Created by 유지수 on 10/30/24.
//

import SwiftUI
import PDFKit

struct SplitDocumentDetails {
    var documentID: String
    var document: PDFDocument
    var head: String
}

struct FloatingSplitView: View {
    
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    
    @ObservedObject var observableDocument: ObservableDocument
    
    let documentID: String
    let document: PDFDocument
    let head: String
    let isFigSelected: Bool
    let onSelect: () -> Void
    
    init(documentID: String, document: PDFDocument, head: String, isFigSelected: Bool, onSelect: @escaping () -> Void) {
        self.document = document
        _observableDocument = ObservedObject(wrappedValue: ObservableDocument(document: document))
        
        self.documentID = documentID
        self.head = head
        self.isFigSelected = isFigSelected
        self.onSelect = onSelect
    }
    
    @State private var isVertical = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 0) {
                        Button(action: {
                            floatingViewModel.setFloatingDocument(documentID: documentID)
                        }, label: {
                            Image(systemName: "rectangle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        .padding(.horizontal, 20)
                        
                        Button(action: {
                            onSelect()
                        }, label: {
                            Image(systemName: isVertical ? "arrow.left.arrow.right" : "arrow.up.arrow.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        
                        Spacer()
                        
                        Button(action: {
                            floatingViewModel.deselect(documentID: documentID)
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        .padding(.trailing, 20)
                    }
                    
                    HStack(spacing: 0) {
                        Spacer()
                        Button(action: {
                            floatingViewModel.moveToPreviousFigure(mainPDFViewModel: mainPDFViewModel, observableDocument: observableDocument)
                        }, label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        Text(head)
                            .reazyFont(.h3)
                            .foregroundStyle(.gray800)
                            .padding(.horizontal, 24)
                        Button(action: {
                            floatingViewModel.moveToNextFigure(mainPDFViewModel: mainPDFViewModel, observableDocument: observableDocument)
                        }, label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        Spacer()
                    }
                }
                .padding(.vertical, 10)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.gray300)
                
                PDFKitView(document: observableDocument.document, isScrollEnabled: true)
                    .id(observableDocument.document)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                
                
                if isFigSelected {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray300)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(0..<mainPDFViewModel.figureAnnotations.count, id: \.self) { index in
                                    FigureCell(index: index, onSelect: { newDocumentID, newDocument, newHead in
                                        if floatingViewModel.selectedFigureCellID != newDocumentID {
                                            floatingViewModel.updateSplitDocument(with: newDocument, documentID: newDocumentID, head: newHead)
                                            observableDocument.updateDocument(to: newDocument)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation {
                                                    proxy.scrollTo(index, anchor: .center)
                                                }
                                            }
                                        }
                                    })
                                    .environmentObject(mainPDFViewModel)
                                    .environmentObject(floatingViewModel)
                                    .padding(.trailing, 5)
                                    .id(index)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(floatingViewModel.selectedFigureIndex, anchor: .center)
                                }
                            }
                        }
                        .onChange(of: floatingViewModel.selectedFigureIndex) { oldIndex , newIndex in
                            if oldIndex != newIndex {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(newIndex, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: isVertical ? geometry.size.height * 0.2 : geometry.size.height * 0.3)
                }
            }
            .onAppear {
                updateOrientation(with: geometry)
            }
            .onChange(of: geometry.size) {
                updateOrientation(with: geometry)
            }
        }
    }
    
    // 기기의 방향에 따라 isVertical 상태를 업데이트하는 함수
    private func updateOrientation(with geometry: GeometryProxy) {
        isVertical = geometry.size.height > geometry.size.width
    }
}
