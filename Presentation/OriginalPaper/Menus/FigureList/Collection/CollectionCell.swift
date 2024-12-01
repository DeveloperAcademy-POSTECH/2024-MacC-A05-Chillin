//
//  CollectionCell.swift
//  Reazy
//
//  Created by 유지수 on 11/27/24.
//

import SwiftUI
import PDFKit

struct CollectionCell: View {
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
    let id: UUID
    let onSelect: (UUID, String, PDFDocument, String) -> Void
    
    @State private var aspectRatio: CGFloat = 1.0
    @State private var newFigName: String = ""
    @State private var isDeleteFigAlert: Bool = false
    
    @State private var isSavedLocation: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack  {
                if let collection = focusFigureViewModel.collections.first(where: { $0.uuid == id }),
                   let index = focusFigureViewModel.collections.firstIndex(where: { $0.uuid == id }),
                   focusFigureViewModel.collectionDocuments.indices.contains(index) {
                    
                    let document = focusFigureViewModel.collectionDocuments[index]
                    if let page = document.page(at: 0) {
                        let pageRect = page.bounds(for: .mediaBox)
                        let aspectRatio = pageRect.width / pageRect.height
                        let head = collection.head
                        let documentID = collection.id
                        let id = collection.uuid
                        
                        PDFKitView(document: document, isScrollEnabled: false)
                            .edgesIgnoringSafeArea(.all)                    // 전체 화면에 맞추기
                            .padding(8)
                            .aspectRatio(aspectRatio, contentMode: .fit)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    if floatingViewModel.selectedFigureCellID != id {
                                        onSelect(id, documentID, document, head)
                                    }
                                }
                            )
                        
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(floatingViewModel.isFigureSelected(documentID: documentID) ? .primary1 : .primary3, lineWidth: floatingViewModel.isFigureSelected(documentID: documentID) ? 1.5 : 1)
                        
                        
                        CollectionMenu(
                            observableDocument: ObservableDocument(document: document),
                            newFigName: $newFigName,
                            isDeleteFigAlert: $isDeleteFigAlert,
                            isSavedLocation: $isSavedLocation,
                            id: id
                        )
                        
                        if floatingViewModel.isSaveImgAlert && focusFigureViewModel.selectedID == id && isSavedLocation {
                            VStack {
                                Text("사진 앱에 저장되었습니다")
                                    .padding()
                                    .frame(width: 190, height: 40)
                                    .reazyFont(.h3)
                                    .background(Color.gray700)
                                    .foregroundStyle(.gray100)
                                    .cornerRadius(12)
                                    .transition(.opacity)
                                    .zIndex(1)
                            }
                            .onDisappear {
                                isSavedLocation = false
                            }
                        }
                    }
                } else {
                    Text("pdf 로드 실패 ")
                }
            }
            .padding(.bottom, 10)
            
            Text(focusFigureViewModel.collections.first(where: { $0.uuid == id })?.head ?? "")
                .reazyFont(.body3)
                .foregroundStyle(.gray800)
        }
    }
}
