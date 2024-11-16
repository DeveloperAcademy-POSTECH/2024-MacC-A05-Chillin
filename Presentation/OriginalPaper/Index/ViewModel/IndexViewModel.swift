//
//  IndexViewModel.swift
//  Reazy
//
//  Created by 김예림 on 10/18/24.
//

import Foundation
import PDFKit


@MainActor
class IndexViewModel: ObservableObject {
    @Published public var tableItems: [TableItem] = []
    @Published public var selectedDestination: PDFDestination?

    private let indexUseCase: IndexUseCase
    
    init(indexUseCase: IndexUseCase) {
        self.indexUseCase = indexUseCase
    }
    
    public func extractIndex() {
        guard let document = indexUseCase.pdfSharedData.document else { return }
        
        self.tableItems = indexUseCase.extractToc(from: document)
    }
}
