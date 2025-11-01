//
//  Set + Extension.swift
//  Reazy
//
//  Created by 문인범 on 7/25/25.
//

import Foundation
import SwiftUI

// 왼쪽
extension Set<MainPDFViewStatus> {
    public var isMenuSelected: Bool {
        self.contains { $0 == .menu(.annotation) || $0 == .menu(.page) || $0 == .menu(.index) }
    }
    
    mutating public func menuToggle() {
        let idx = self.firstIndex {
            $0 == .menu(.annotation) || $0 == .menu(.page) || $0 == .menu(.index)
        }
        
        if let idx = idx {
            self.remove(at: idx)
        } else {
            self.insert(.menu(.index))
            self.remove(.search)
        }
    }
    
    mutating public func menuOff() {
        let idx = self.firstIndex {
            $0 == .menu(.annotation) || $0 == .menu(.page) || $0 == .menu(.index)
        }
        
        if let idx = idx {
            self.remove(at: idx)
        }
    }
}

extension Set<MainPDFViewStatus> {
    public var isSearchSelected: Bool {
        self.contains(.search)
    }
    
    mutating public func searchToggle() {
        if isSearchSelected {
            self.remove(.search)
        } else {
            self.insert(.search)
            self.menuOff()
        }
    }
}

extension Set<MainPDFViewStatus> {
    public var isConcentrateSelected: Bool {
        self.contains(.concentrate)
    }
    
    mutating public func concentrateToggle() {
        if isConcentrateSelected {
            self.remove(.concentrate)
        } else {
            self.insert(.concentrate)
        }
    }
}

// 가운데
extension Set<MainPDFViewStatus> {
    public var isCenterMenuSelected: Bool {
        isToolSelected || isCommentSelected || isTranslationSelected || isCaptureSelected
    }
    
    mutating public func centerMenuOff() {
        self.remove(.tool(.pencil))
        self.remove(.tool(.eraser))
        self.remove(.tool(.highlight))
        self.remove(.translation)
        self.remove(.comment)
    }
    
    mutating public func toggleCenterButton(button: Buttons) {
        switch button {
        case .drawing:
            toolToggle()
        case .comment:
            commentToggle()
        case .translate:
            translationToggle()
        }
    }
    
    public func centerMenuForegroundColor(button: Buttons) -> Color {
        switch button {
        case .drawing:
            isToolSelected ? .gray100 : .gray800
        case .comment:
            isCommentSelected ? .gray100 : .gray800
        case .translate:
            isTranslationSelected ? .gray100 : .gray800
        }
    }
    
    public func centerMenuBackgroundColor(button: Buttons) -> Color {
        switch button {
        case .drawing:
            isToolSelected ? .primary1 : .clear
        case .comment:
            isCommentSelected ? .primary1 : .clear
        case .translate:
            isTranslationSelected ? .primary1 : .clear
        }
    }
}


extension Set<MainPDFViewStatus> {
    public var isToolSelected: Bool {
        self.contains { $0 == .tool(.eraser) || $0 == .tool(.highlight) || $0 == .tool(.pencil) || $0 == .tool(.none) }
    }
    
    public var isHighlightSelected: Bool {
        self.contains(.tool(.highlight))
    }
    
    public var isEraserSelected: Bool {
        self.contains(.tool(.eraser))
    }
    
    public var isPencilSelected: Bool {
        self.contains(.tool(.pencil))
    }
    
    public var toolWidth: CGFloat {
        if isEraserSelected {
            5
        } else if isPencilSelected {
            0.5
        } else {
            0
        }
    }
    
    public var toolAlpha: CGFloat {
        1
    }
    
    
    mutating public func toolToggle() {
        if isToolSelected {
            toolOff()
        } else {
            self.insert(.tool(.none))
            self.remove(.comment)
            self.remove(.translation)
            self.remove(.capture)
        }
    }
    
    mutating public func highlightToggle() {
        if self.contains(.tool(.highlight)) {
            self.remove(.tool(.highlight))
            self.insert(.tool(.none))
        } else {
            self.onHighlight()
        }
    }
    
    mutating public func togglePencil() {
        if self.contains(.tool(.pencil)) {
            self.remove(.tool(.pencil))
            self.insert(.tool(.none))
        } else {
            self.onPencil()
        }
    }
    
    mutating public func toggleEraser() {
        if self.contains(.tool(.eraser)) {
            self.remove(.tool(.eraser))
            self.insert(.tool(.none))
        } else {
            self.onEraser()
        }
    }
    
    // TODO: ON 할시 나머지 안쓰는거 제거 필요
    mutating public func onHighlight() {
        self.insert(.tool(.highlight))
        self.remove(.tool(.eraser))
        self.remove(.tool(.pencil))
        self.remove(.tool(.none))
    }
    
    mutating public func onPencil() {
        self.insert(.tool(.pencil))
        self.remove(.tool(.highlight))
        self.remove(.tool(.eraser))
        self.remove(.tool(.none))
    }
    
    mutating public func onEraser() {
        self.insert(.tool(.eraser))
        self.remove(.tool(.highlight))
        self.remove(.tool(.pencil))
        self.remove(.tool(.none))
    }
    
    mutating public func toolOff() {
        self.remove(.tool(.eraser))
        self.remove(.tool(.highlight))
        self.remove(.tool(.pencil))
        self.remove(.tool(.none))
    }
}


extension Set<MainPDFViewStatus> {
    public var isTranslationSelected: Bool {
        self.contains(.translation)
    }
    
    mutating public func translationToggle() {
        if isTranslationSelected {
            self.remove(.translation)
        } else {
            self.insert(.translation)
            self.remove(.comment)
            self.remove(.capture)
            self.toolOff()
        }
    }
}

extension Set<MainPDFViewStatus> {
    public var isCommentSelected: Bool {
        self.contains(.comment)
    }
    
    mutating public func commentToggle() {
        if isCommentSelected {
            self.remove(.comment)
        } else {
            self.insert(.comment)
            self.remove(.translation)
            self.remove(.capture)
            self.toolOff()
        }
    }
}

extension Set<MainPDFViewStatus> {
    public var isCaptureSelected: Bool {
        self.contains(.capture)
    }
    
    mutating public func captureToggle() {
        if isCaptureSelected {
            self.remove(.capture)
        } else {
            self.insert(.capture)
            self.remove(.comment)
            self.remove(.translation)
            self.toolOff()
        }
    }
    
    mutating public func captureOff() {
        self.remove(.capture)
    }
}


// 오른쪽
extension Set<MainPDFViewStatus> {
    public var isFigureSelected: Bool {
        self.contains(.figure)
    }
    
    mutating public func figureToggle() {
        self.remove(.capture)
        if isFigureSelected {
            self.remove(.figure)
        } else {
            self.insert(.figure)
            self.remove(.collection)
            self.remove(.detail)
        }
    }
    
    mutating public func figureOff() {
        self.remove(.figure)
    }
}


extension Set<MainPDFViewStatus> {
    public var isCollectionSelected: Bool {
        self.contains(.collection)
    }
    
    mutating public func collectionToggle() {
        self.remove(.capture)
        if isCollectionSelected {
            self.remove(.collection)
        } else {
            self.insert(.collection)
            self.remove(.figure)
            self.remove(.detail)
        }
    }
}



extension Set<MainPDFViewStatus> {
    public var isDetailSelected: Bool {
        self.contains(.detail)
    }
    
    mutating public func detailToggle() {
        if isDetailSelected {
            self.remove(.detail)
        } else {
            self.insert(.detail)
            self.remove(.collection)
            self.remove(.figure)
        }
    }
    
    mutating public func detailOff() {
        self.remove(.detail)
    }
}
