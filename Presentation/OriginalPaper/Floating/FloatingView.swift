//
//  FloatingView.swift
//  Reazy
//
//  Created by 유지수 on 10/20/24.
//

import SwiftUI
import PDFKit

struct FloatingView: View {
    
    let id: UUID
    let isFigure: Bool
    let documentID: String
    let document: PDFDocument
    let head: String
    
    @Binding var isSelected: Bool
    @Binding var viewOffset: CGSize
    @Binding var viewWidth: CGFloat
    
    @State private var aspectRatio: CGFloat = 1.0
    
    @State private var isSavedLocation: Bool = false
    
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @ObservedObject var observableDocument: ObservableDocument
    
    init(id: UUID, isFigure: Bool, documentID: String, document: PDFDocument, head: String, isSelected: Binding<Bool>, viewOffset: Binding<CGSize>, viewWidth: Binding<CGFloat>) {
        self.document = document
        _observableDocument = ObservedObject(wrappedValue: ObservableDocument(document: document))
        
        self.id = id
        self.isFigure = isFigure
        self.documentID = documentID
        self.head = head
        self._isSelected = isSelected
        self._viewOffset = viewOffset
        self._viewWidth = viewWidth
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: {
                    floatingViewModel.isFigure = isFigure
                    
                    let uuid = {
                        if isFigure { return focusFigureViewModel.figures.first(where: { $0.id == documentID })?.uuid }
                        else { return focusFigureViewModel.collections.first(where: { $0.id == documentID })?.uuid }
                    }()
                    let index = {
                        if isFigure { return focusFigureViewModel.getFigureIndex(id: uuid!) }
                        else { return focusFigureViewModel.getCollectionIndex(id: uuid!) }
                    }()
                    floatingViewModel.selectedFigureCellID = uuid
                    floatingViewModel.setSplitDocument(at: index, uuid: id)
                }, label: {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray600)
                })
                .padding(.leading, 20)
                
                Rectangle()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.clear)
                
                Spacer()
                
                Text(head)
                    .reazyFont(.body1)
                    .foregroundStyle(.gray800)
                
                Spacer()
                
                Menu {
                    Button(action: {
                        self.focusFigureViewModel.selectedID = id
                        self.floatingViewModel.saveFigImage(document: observableDocument)
                        self.floatingViewModel.saveFigAlert()
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
                        .font(.system(size: 14))
                        .foregroundStyle(.gray600)
                })
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 10)
            .frame(height: 40)
            
            Divider()
            
            ZStack {
                PDFKitView(document: observableDocument.document, isScrollEnabled: true)
                    .id(observableDocument.document)
                    .frame(width: viewWidth - 36, height: (viewWidth - 36) / aspectRatio)
                    .padding(.horizontal, 20)
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
                    }
                    .padding(.bottom, 48)
                    .onDisappear {
                        isSavedLocation = false
                    }
                }
            }
        }
        .frame(width: viewWidth)
        .padding(.vertical, 11)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                            let newWidth = max(min(viewWidth + value.translation.width, 850), 500)
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
