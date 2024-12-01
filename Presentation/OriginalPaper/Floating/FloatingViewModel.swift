//
//  FloatingViewModel.swift
//  Reazy
//
//  Created by 유지수 on 10/29/24.
//

import SwiftUI
import PDFKit
import Combine

struct DroppedFigure: Identifiable {
    var id: UUID
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
    
    @Published var selectedFigureCellID: UUID?
    @Published var selectedFigureIndex: Int = 0
    @Published var isFigure: Bool = false
    
    @Published var splitMode: Bool = false
    @Published var isSaveImgAlert: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    
    func toggleSelection(id: UUID, for documentID: String, document: PDFDocument, head: String) {
        if let index = droppedFigures.firstIndex(where: { $0.documentID == documentID }) {
            droppedFigures[index].isSelected.toggle()
            
            if droppedFigures[index].isSelected {
                topmostIndex = index
            }
        } else {
            let newFigure = DroppedFigure(
                id: id,
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
    
    func deselect(uuid: UUID) {
        if let index = droppedFigures.firstIndex(where: { $0.id == uuid }) {
            droppedFigures[index].isSelected = false
            droppedFigures[index].isInSplitMode = false
            
            if splitMode && selectedFigureCellID == uuid {
                splitMode = false
                selectedFigureCellID = nil
            }
            
            droppedFigures.remove(at: index)
        }
    }
    
    func isFigureSelected(documentID: String) -> Bool {
        return droppedFigures.first { $0.documentID == documentID }?.isSelected ?? false
    }
    
    func setSplitDocument(at index: Int, uuid: UUID) {
        DispatchQueue.main.async {
            self.selectedFigureCellID = uuid
            self.splitMode = true
            
            self.selectedFigureIndex = index
            
            if let index = self.droppedFigures.firstIndex(where: { $0.id == uuid }) {
                self.droppedFigures[index].isInSplitMode = true
            }
            
            self.droppedFigures = self.droppedFigures.filter { $0.id == uuid }
            
            self.selectedFigureCellID = uuid
        }
    }
        
    func setFloatingDocument(uuid: UUID) {
        self.selectedFigureCellID = uuid
        self.splitMode = false
        
        if let index = droppedFigures.firstIndex(where: { $0.id == uuid }) {
            droppedFigures[index].isInSplitMode = false
        }
    }
    
    func updateSplitDocument(isFigure: Bool, with newDocument: PDFDocument, uuid: UUID, documentID: String, head: String) {
        guard splitMode, let currentSelectedID = selectedFigureCellID else { return }
        
        self.isFigure = isFigure
        
        if currentSelectedID != uuid {
            if let existingIndex = droppedFigures.firstIndex(where: { $0.id == selectedFigureCellID }) {
                droppedFigures[existingIndex].id = uuid
                droppedFigures[existingIndex].documentID = documentID
                droppedFigures[existingIndex].document = newDocument
                droppedFigures[existingIndex].head = head
                droppedFigures[existingIndex].isSelected = true
                droppedFigures[existingIndex].isInSplitMode = true
                
                selectedFigureCellID = uuid
                selectedFigureIndex = existingIndex
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
        let lists = isFigure ? focusFigureViewModel.figures : focusFigureViewModel.collections
        
        guard let nextUUID = getNextUUID(currentUUID: selectedFigureCellID!, in: lists) else {
            return
        }
        
        moveToFigure(at: nextUUID, focusFigureViewModel: focusFigureViewModel, observableDocument: observableDocument)
    }
    
    @MainActor
    func moveToPreviousFigure(focusFigureViewModel: FocusFigureViewModel, observableDocument: ObservableDocument) {
        let lists = isFigure ? focusFigureViewModel.figures : focusFigureViewModel.collections
        
        guard let previousUUID = getPreviousUUID(currentUUID: selectedFigureCellID ?? UUID(), in: lists) else {
            return
        }
        
        moveToFigure(at: previousUUID, focusFigureViewModel: focusFigureViewModel, observableDocument: observableDocument)
    }
    
    @MainActor
    private func moveToFigure(at uuid: UUID, focusFigureViewModel: FocusFigureViewModel, observableDocument: ObservableDocument) {
        let lists = isFigure ? focusFigureViewModel.figures : focusFigureViewModel.collections
        
        guard let index = lists.firstIndex(where: { $0.uuid == uuid }) else {
            return
        }
        
        let figure = lists[index]
        let document = isFigure ? focusFigureViewModel.figureDocuments[index] : focusFigureViewModel.collectionDocuments[index]

        updateSplitDocument(isFigure: isFigure, with: document, uuid: figure.uuid, documentID: figure.id, head: figure.head)
        observableDocument.updateDocument(to: document)
        
        selectedFigureIndex = index
        selectedFigureCellID = uuid
    }
    
    func getSplitDocumentDetails() -> SplitDocumentDetails? {
        guard splitMode, let selectedID = selectedFigureCellID else { return nil }
        if let selectedFigure = droppedFigures.first(where: { $0.id == selectedID }) {
            return SplitDocumentDetails(
                id: selectedFigure.id,
                documentID: selectedFigure.documentID,
                document: selectedFigure.document,
                head: selectedFigure.head
            )
        }
        return nil
    }
    
    func getNextUUID(currentUUID: UUID, in array: [FigureAnnotation]) -> UUID? {
        guard let currentIndex = array.firstIndex(where: { $0.uuid == currentUUID }) else {
            return nil
        }
        
        let nextIndex = (currentIndex + 1) % array.count
        
        return array[nextIndex].uuid
    }
    
    func getPreviousUUID(currentUUID: UUID, in array: [FigureAnnotation]) -> UUID? {
        guard let currentIndex = array.firstIndex(where: { $0.uuid == currentUUID }) else {
            return nil
        }
        
        let previousIndex = (currentIndex - 1 + array.count) % array.count
        
        return array[previousIndex].uuid
    }
}

extension FloatingViewModel {
    @MainActor
    func subscribeToFocusFigureViewModel(_ focusFigureViewModel: FocusFigureViewModel) {
        focusFigureViewModel.figureUpdatedPublisher
            .sink { [weak self] figure in
                self?.handleNewFigure(figure, from: focusFigureViewModel)
            }
            .store(in: &cancellables)
        
        focusFigureViewModel.collectionUpdatedPublisher
            .sink { [weak self] collection in
                self?.handleNewCollection(collection, from: focusFigureViewModel)
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func handleNewFigure(_ figure: FigureAnnotation, from focusFigureViewModel: FocusFigureViewModel) {
        
        if let index = focusFigureViewModel.figures.firstIndex(where: { $0.uuid == figure.uuid }) {
            guard let document = focusFigureViewModel.setFigureDocument(for: index) else { return }
            
            self.isFigure = true
                    
            toggleSelection(id: figure.uuid, for: figure.id, document: document, head: figure.head)
        }
    }
    
    @MainActor
    private func handleNewCollection(_ collection: FigureAnnotation, from focusFigureViewModel: FocusFigureViewModel) {
        
        if let index = focusFigureViewModel.collections.firstIndex(where: { $0.uuid == collection.uuid }) {
            guard let document = focusFigureViewModel.setCollectionDocument(for: index) else { return }
            
            self.isFigure = false
            
            toggleSelection(id: collection.uuid, for: collection.id, document: document, head: collection.head)
        }
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
