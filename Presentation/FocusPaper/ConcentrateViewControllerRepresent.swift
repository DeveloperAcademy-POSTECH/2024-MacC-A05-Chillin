//
//  ConcentrateViewControllerRepresent.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation
import SwiftUI

/**
 집중 모드 vc SwiftUI 로 변환
 */


struct ConcentrateViewControllerRepresent: UIViewControllerRepresentable {
    typealias UIViewControllerType = ConcentrateViewController
    
    @EnvironmentObject var viewModel: FocusFigureViewModel
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        ConcentrateViewController(viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: ConcentrateViewController, context: Context) {
        
    }
}

