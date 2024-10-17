//
//  MainPDFViewModel.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation
import PDFKit


final class MainPDFViewModel: ObservableObject {
    
    static let shared = MainPDFViewModel()
    
    var document: PDFDocument?
    
    private init() {}
}

