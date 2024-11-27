//
//  FloatingViewModel.swift
//  Reazy
//
//  Created by 유지수 on 10/29/24.
//

import SwiftUI
import PDFKit

struct DroppedFigure: Identifiable {
    let id: UUID = UUID()
    var documentID: String
    var document: PDFDocument
    var head: String
    var isSelected: Bool
    var viewOffset: CGSize
    var lastOffset: CGSize
    var viewWidth: CGFloat
    var isInSplitMode: Bool
    var isFigure: Bool
}

class FloatingViewModel: ObservableObject {
    @Published var droppedFigures: [DroppedFigure] = []
    @Published var topmostIndex: Int?
    
    @Published var selectedFigureCellID: String?
    @Published var selectedFigureIndex: Int = 0
    @Published var isFigure: Bool = false
    
    @Published var splitMode: Bool = false
    @Published var isSaveImgAlert: Bool = false
    
    func toggleSelection(for documentID: String, document: PDFDocument, head: String) {
        if let index = droppedFigures.firstIndex(where: { $0.documentID == documentID }) {
            droppedFigures[index].isSelected.toggle()
            
            if droppedFigures[index].isSelected {
                topmostIndex = index
            }
        } else {
            let newFigure = DroppedFigure(
                documentID: documentID,
                document: document,
                head: head,
                isSelected: true,
                viewOffset: CGSize(width: 0, height: 0),
                lastOffset: CGSize(width: 0, height: 0),
                viewWidth: 300,
                isInSplitMode: false,
                isFigure: isFigure
            )
            droppedFigures.append(newFigure)
            
            topmostIndex = droppedFigures.count - 1
        }
    }
    
    func deselect(documentID: String) {
        if let index = droppedFigures.firstIndex(where: { $0.documentID == documentID }) {
            droppedFigures[index].isSelected = false
            droppedFigures[index].isInSplitMode = false
            
            if splitMode && selectedFigureCellID == documentID {
                splitMode = false
                selectedFigureCellID = nil
            }
            
            droppedFigures.remove(at: index)
        }
    }
    
    func isFigureSelected(documentID: String) -> Bool {
        return droppedFigures.first { $0.documentID == documentID }?.isSelected ?? false
    }
    
    func setSplitDocument(documentID: String) {
        DispatchQueue.main.async {
            self.selectedFigureCellID = documentID
            self.splitMode = true
            
            if let index = Int(documentID.components(separatedBy: "-").last ?? "") {
                self.selectedFigureIndex = index
            }
            
            if let index = self.droppedFigures.firstIndex(where: { $0.documentID == documentID }) {
                self.droppedFigures[index].isInSplitMode = true
            }
            
            self.droppedFigures = self.droppedFigures.filter { $0.documentID == documentID }
            
            self.selectedFigureCellID = documentID
        }
    }
        
    func setFloatingDocument(documentID: String) {
        self.selectedFigureCellID = documentID
        self.splitMode = false
        
        if let index = droppedFigures.firstIndex(where: { $0.documentID == documentID }) {
            droppedFigures[index].isInSplitMode = false
        }
    }
    
    func updateSplitDocument(isFigure: Bool, with newDocument: PDFDocument, documentID: String, head: String) {
        guard splitMode, let currentSelectedID = selectedFigureCellID else { return }
        
        self.isFigure = isFigure
        
        if currentSelectedID != documentID {
            if let existingIndex = droppedFigures.firstIndex(where: { $0.documentID == selectedFigureCellID }) {
                droppedFigures[existingIndex].documentID = documentID
                droppedFigures[existingIndex].document = newDocument
                droppedFigures[existingIndex].head = head
                droppedFigures[existingIndex].isSelected = true
                droppedFigures[existingIndex].isInSplitMode = true
                
                selectedFigureCellID = documentID
                selectedFigureIndex = Int(documentID.components(separatedBy: "-").last ?? "") ?? 0
            }
        }
    }
    
    // Fig 이미지 저장 함수
    func saveFigImage(document: ObservableDocument) {
        let pdfDocument = document.document
        guard let pdfPage = pdfDocument.page(at: 0) else { return }
        
        // PDF 페이지를 UIImage로 변환
        let pdfPageBounds = pdfPage.bounds(for: .mediaBox)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 5.0              // 스케일 조정 -> 높은 화질
        format.opaque = false           // 배경 투명 설정 false
        let renderer = UIGraphicsImageRenderer(size: pdfPageBounds.size, format: format)
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            
            context.fill(CGRect(origin: .zero, size: pdfPageBounds.size))
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: pdfPageBounds.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            pdfPage.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }
        
        // 이미지 저장
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    // Fig 이미지 저장 Alert 함수
    func saveFigAlert() {
        withAnimation {
            isSaveImgAlert = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.isSaveImgAlert = false
            }
        }
    }

    
    @MainActor
    func moveToNextFigure(focusFigureViewModel: FocusFigureViewModel, observableDocument: ObservableDocument) {
        let lists = {
            if isFigure { return focusFigureViewModel.figures }
            else { return focusFigureViewModel.collections }
        }()
        
        let newIndex = (selectedFigureIndex + 1) % lists.count
        DispatchQueue.main.async {
            self.selectedFigureIndex = newIndex
            self.moveToFigure(at: newIndex, focusFigureViewModel: focusFigureViewModel, observableDocument: observableDocument)
        }
    }
    
    @MainActor
    func moveToPreviousFigure(focusFigureViewModel: FocusFigureViewModel, observableDocument: ObservableDocument) {
        let lists = {
            if isFigure { return focusFigureViewModel.figures }
            else { return focusFigureViewModel.collections }
        }()
        
        let newIndex = (selectedFigureIndex - 1 + lists.count) % focusFigureViewModel.figures.count
        DispatchQueue.main.async {
            self.selectedFigureIndex = newIndex
            self.moveToFigure(at: newIndex, focusFigureViewModel: focusFigureViewModel, observableDocument: observableDocument)
        }
    }
    
    @MainActor
    private func moveToFigure(at index: Int, focusFigureViewModel: FocusFigureViewModel, observableDocument: ObservableDocument) {
        let lists = {
            if isFigure { return focusFigureViewModel.figures }
            else { return focusFigureViewModel.collections }
        }()
        let documents = {
            if isFigure { return focusFigureViewModel.figureDocuments }
            else { return focusFigureViewModel.collectionDocuments }
        }()
        
        guard index < lists.count, index < documents.count else {
            print("Invalid index")
            return
        }
        
        let figure = lists[index]
        let document = documents[index]

        updateSplitDocument(isFigure: isFigure, with: document, documentID: figure.id, head: figure.head)
        observableDocument.updateDocument(to: document)
        
        selectedFigureIndex = index
    }
    
    func getSplitDocumentDetails() -> SplitDocumentDetails? {
        guard splitMode, let selectedID = selectedFigureCellID else { return nil }
        if let selectedFigure = droppedFigures.first(where: { $0.documentID == selectedID }) {
            return SplitDocumentDetails(
                documentID: selectedFigure.documentID,
                document: selectedFigure.document,
                head: selectedFigure.head
            )
        }
        return nil
    }
}

class ObservableDocument: ObservableObject {
    @Published var document: PDFDocument
    
    init(document: PDFDocument) {
        self.document = document
    }
    
    func updateDocument(to newDocument: PDFDocument) {
        document = newDocument
    }
}
