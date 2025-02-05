//
//  BackPageButtonViewModel.swift
//  Reazy
//
//  Created by 김예림 on 1/31/25.
//

import Foundation
import PDFKit

@MainActor
class BackPageBtnViewModel: ObservableObject {
    private let BackPageBtnUsecase: BackPageBtnUseCase
    
    init(BackPageBtnUsecase: BackPageBtnUseCase) {
        self.BackPageBtnUsecase = BackPageBtnUsecase
    }
    
    @Published var backPageDestination: PDFDestination?
    @Published var backScaleFactor: CGFloat = .zero
    @Published var isLinkTapped: Bool = false
    
    func updateTempDestination(_ destination: PDFDestination) {
        BackPageBtnUsecase.updateTempDestination(destination)
    }
    
    func updateBackDestination() {
        if let destination = BackPageBtnUsecase.tempDestination {
            backPageDestination = BackPageBtnUsecase.convertDestination(for: destination)
        }
    }
    
    func setDestination(pdfView: PDFView) {
        if let destination = BackPageBtnUsecase.getTopLeadingDestination(pdfView: pdfView, scaleFactor: backScaleFactor) {
            BackPageBtnUsecase.updateTempDestination(destination)
        }
    }
    
}
