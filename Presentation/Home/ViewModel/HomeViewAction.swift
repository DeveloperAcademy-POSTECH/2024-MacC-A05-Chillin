//
//  HomeViewAction.swift
//  Reazy
//
//  Created by 문인범 on 7/24/25.
//

import Foundation
import SwiftUI


enum HomeViewAction: Hashable {
    case setting
    
    case creatingFolder
    case creatingMovingFolder(UUID?)
    case editingFolder
    case movingFolder
    
    case creatingTag
    case addTagToPaper(PaperInfo)
    case editingPaperTitle(PaperInfo)
    
    case folderPopover(position: CGPoint)
    
    case duplicatedTitleAlert
    case deletingTagAlert(String, UUID)
    case deletingPaperAlert([UUID])
    case deletingFolderAlert
    case folderDepthAlert
    case iCloudOnboardingAlert
    case none
    
    
    public var backgroundOpacity: Double {
        switch self {
        case .none:
            0
        default:
            0.5
        }
    }
    
    public var blurredConstant: CGFloat {
        switch self {
        case .none:
            0
        default:
            5
        }
    }
}
