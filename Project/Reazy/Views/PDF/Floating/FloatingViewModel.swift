//
//  FloatingViewModel.swift
//  Reazy
//
//  Created by 유지수 on 10/29/24.
//

import SwiftUI
import PDFKit

class FloatingViewModel: ObservableObject {
  @Published var droppedFigures: [(documentID: String, document: PDFDocument, head: String, isSelected: Bool, viewOffset: CGSize, lastOffset: CGSize, viewWidth: CGFloat, isInSplitMode: Bool)] = []
  @Published var topmostIndex: Int? = nil
  
  @Published var selectedFigureCellID: String? = nil
  @Published var selectedFigureIndex: Int = 0
  @Published var splitMode: Bool = false
  
  func toggleSelection(for documentID: String, document: PDFDocument, head: String) {
    if let index = droppedFigures.firstIndex(where: { $0.documentID == documentID }) {
      droppedFigures[index].isSelected.toggle()
      if droppedFigures[index].isSelected {
        topmostIndex = index
      }
    } else {
      droppedFigures.append((
        documentID: documentID,
        document: document,
        head: head,
        isSelected: true,
        viewOffset: CGSize(width: 0, height: 0),
        lastOffset: CGSize(width: 0, height: 0),
        viewWidth: 300,
        isInSplitMode: false
      ))
      topmostIndex = droppedFigures.count - 1
    }
    droppedFigures = droppedFigures.map { $0 }
  }
  
  func deselect(documentID: String) {
    if let index = droppedFigures.firstIndex(where: { $0.documentID == documentID }) {
      droppedFigures[index].isSelected = false
      droppedFigures[index].isInSplitMode = false
      
      if splitMode && selectedFigureCellID == documentID {
        splitMode = false
        selectedFigureCellID = nil
      }
      
      droppedFigures = droppedFigures.map { $0 }
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
      
      for i in 0..<self.droppedFigures.count where self.droppedFigures[i].documentID != documentID {
        self.droppedFigures[i].isSelected = false
      }
      
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
  
  func updateSplitDocument(with newDocument: PDFDocument, documentID: String, head: String) {
    if splitMode, let currentSelectedID = selectedFigureCellID {
      if currentSelectedID != documentID {
        if let existingIndex = droppedFigures.firstIndex(where: { $0.documentID == selectedFigureCellID }) {
          droppedFigures[existingIndex] = (
            documentID: documentID,
            document: newDocument,
            head: head,
            isSelected: true,
            viewOffset: droppedFigures[existingIndex].viewOffset,
            lastOffset: droppedFigures[existingIndex].lastOffset,
            viewWidth: droppedFigures[existingIndex].viewWidth,
            isInSplitMode: true
          )
          
          selectedFigureCellID = documentID
          if let index = Int(documentID.components(separatedBy: "-").last ?? "") {
            selectedFigureIndex = index
          }
          droppedFigures = droppedFigures.map { $0 }
        }
      }
    }
  }
  
  func moveToNextFigure(mainPDFViewModel: MainPDFViewModel, observableDocument: ObservableDocument) {
    let newIndex = (selectedFigureIndex + 1) % mainPDFViewModel.figureAnnotations.count
    DispatchQueue.main.async {
      self.selectedFigureIndex = newIndex
      self.moveToFigure(at: newIndex, mainPDFViewModel: mainPDFViewModel, observableDocument: observableDocument)
    }
  }
  
  func moveToPreviousFigure(mainPDFViewModel: MainPDFViewModel, observableDocument: ObservableDocument) {
    let newIndex = (selectedFigureIndex - 1 + mainPDFViewModel.figureAnnotations.count) % mainPDFViewModel.figureAnnotations.count
    DispatchQueue.main.async {
      self.selectedFigureIndex = newIndex
      self.moveToFigure(at: newIndex, mainPDFViewModel: mainPDFViewModel, observableDocument: observableDocument)
    }
  }
  
  private func moveToFigure(at index: Int, mainPDFViewModel: MainPDFViewModel, observableDocument: ObservableDocument) {
    guard let document = mainPDFViewModel.setFigureDocument(for: index) else { return }
    let figure = mainPDFViewModel.figureAnnotations[index]
    
    updateSplitDocument(with: document, documentID: "figure-\(index)", head: figure.head)
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
