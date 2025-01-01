//
//  FloatingSplitView.swift
//  Reazy
//
//  Created by 유지수 on 10/30/24.
//

import SwiftUI
import PDFKit
import AVFoundation
import Photos

struct SplitDocumentDetails {
    let id: UUID
    let documentID: String
    let document: PDFDocument
    let head: String
}

struct FloatingSplitView: View {
    
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    
    @ObservedObject var observableDocument: ObservableDocument
    
    let id: UUID
    let documentID: String
    let document: PDFDocument
    let head: String
    let isFigSelected: Bool
    let isCollectionSelected: Bool
    let onSelect: () -> Void
    
    @State private var isSavedLocation: Bool = false
    
    init(id: UUID, documentID: String, document: PDFDocument, head: String, isFigSelected: Bool, isCollectionSelected: Bool, onSelect: @escaping () -> Void) {
        self.document = document
        _observableDocument = ObservedObject(wrappedValue: ObservableDocument(document: document))
        
        self.id = id
        self.documentID = documentID
        self.head = head
        self.isFigSelected = isFigSelected
        self.isCollectionSelected = isCollectionSelected
        self.onSelect = onSelect
    }
    
    @State private var isVertical = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 0) {
                        Button(action: {
                            floatingViewModel.setFloatingDocument(uuid: id)
                        }, label: {
                            Image(systemName: "rectangle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        .padding(.leading, 20)
                        .padding(.trailing, 24)
                        
                        Button(action: {
                            onSelect()
                        }, label: {
                            Image(systemName: isVertical ? "arrow.left.arrow.right" : "arrow.up.arrow.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        
                        Spacer()
                        
                        Menu {
                            Button(action: {
                                self.focusFigureViewModel.selectedID = id
                                floatingViewModel.saveFigImage(document: observableDocument)
                                floatingViewModel.saveFigAlert()
                                self.isSavedLocation = true
                                
                                print("Download Image")
                                
                            }, label: {
                                Text("사진 앱에 저장")
                                    .reazyFont(.body1)
                                    .foregroundStyle(.gray800)
                                    .frame(width: 148)
                            })
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.gray600)
                        }
                        
                        Button(action: {
                            floatingViewModel.deselect(uuid: id)
                        }, label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        .padding(.leading, 24)
                        .padding(.trailing, 20)
                    }
                    
                    HStack(spacing: 0) {
                        Spacer()
                        
                        Button(action: {
                            floatingViewModel.moveToPreviousFigure(focusFigureViewModel: focusFigureViewModel, observableDocument: observableDocument)
                        }, label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        
                        Text(head)
                            .reazyFont(.text1)
                            .foregroundStyle(.gray800)
                            .padding(.horizontal, 24)
                        
                        Button(action: {
                            floatingViewModel.moveToNextFigure(focusFigureViewModel: focusFigureViewModel, observableDocument: observableDocument)
                        }, label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.gray600)
                        })
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 12)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.gray300)
                
                ZStack {
                    PDFKitView(document: observableDocument.document, isScrollEnabled: true)
                        .id(observableDocument.document)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                    
                    if floatingViewModel.isSaveImgAlert && focusFigureViewModel.selectedID == id && isSavedLocation {
                        VStack {
                            Text("사진 앱에 저장되었습니다")
                                .padding()
                                .frame(width: 190, height: 40)
                                .reazyFont(.h3)
                                .background(Color.gray700)
                                .foregroundStyle(.gray100)
                                .cornerRadius(12)
                                .transition(.opacity)                       // 부드러운 전환 효과
                                .zIndex(1)                                  // ZStack에서의 순서 조정
                                .padding(.top, 20)
                            
                            Spacer()
                        }
                        .onDisappear {
                            isSavedLocation = false
                        }
                    }
                }
                
                
                if isFigSelected || isCollectionSelected {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.gray300)
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                if isFigSelected {
                                    ForEach(focusFigureViewModel.figures, id: \.self) { item in
                                        let id = item.uuid
                                        
                                        FigureCell(id: id, onSelect: { id, newDocumentID, newDocument, newHead in
                                            if floatingViewModel.selectedFigureCellID != id {
                                                floatingViewModel.updateSplitDocument(isFigure: true, with: newDocument, uuid: id, documentID: newDocumentID, head: newHead)
                                                observableDocument.updateDocument(to: newDocument)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    withAnimation {
                                                        proxy.scrollTo(id, anchor: .center)
                                                    }
                                                }
                                            }
                                        })
                                        .environmentObject(floatingViewModel)
                                        .padding(.trailing, 5)
                                        .id(id)
                                    }
                                } else {
                                    ForEach(focusFigureViewModel.collections, id: \.self) { item in
                                        let id = item.uuid
                                        
                                        CollectionCell(id: id, onSelect: { id, newDocumentID, newDocument, newHead in
                                            if floatingViewModel.selectedFigureCellID != id {
                                                floatingViewModel.updateSplitDocument(isFigure: false, with: newDocument, uuid: id, documentID: newDocumentID, head: newHead)
                                                observableDocument.updateDocument(to: newDocument)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    withAnimation {
                                                        proxy.scrollTo(id, anchor: .center)
                                                    }
                                                }
                                            }
                                        })
                                        .environmentObject(floatingViewModel)
                                        .padding(.trailing, 5)
                                        .id(id)
                                    }
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
            .background(.gray100)
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
