//
//  MainPDFViewAction.swift
//  Reazy
//
//  Created by 문인범 on 11/1/25.
//

import SwiftUI


enum MainPDFViewAction: Hashable {
    case none
    
    case floating
    case editingPaperTitle(PaperInfo)
    
    case movingFolder
    case creatingMovingFolder(UUID?)
    case folderDepthAlert
    
    case duplicatedTitleAlert
    case deletePaperAlert
    
    public var blurConstant: CGFloat {
        switch self {
        case .none: 0
        default: 20
        }
    }
    
    public var opacityConstant: Double {
        switch self {
        case .none: 0
        default: 0.5
        }
    }
    
    public var isDeletePapersAlertPresented: Binding<Bool> {
        Binding(
            get: { self == .deletePaperAlert },
            set: { _ in }
        )
    }
}
