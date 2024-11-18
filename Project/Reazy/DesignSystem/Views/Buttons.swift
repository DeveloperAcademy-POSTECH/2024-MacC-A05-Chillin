//
//  Buttons.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import SwiftUI

// MARK: - Ver.1 Buttons
enum WriteButton: String, CaseIterable {
    case comment
    case highlight
    case pencil
    case eraser
    case translate
    
    var icon: Image {
        switch self {
        case .comment:
            return Image(systemName: "text.bubble")
        case .highlight:
            return Image("Highlight")
                .renderingMode(.template)
        case .pencil:
            return Image("Pencil")
                .renderingMode(.template)
        case .eraser:
            return Image(systemName: "eraser")
        case .translate:
            return Image(systemName: "globe")
        }
    }
}

enum HighlightColors: String, CaseIterable {
    case yellow
    case pink
    case green
    case blue
    
    var color: Color {
        switch self {
        case .yellow:
            return .highlight1
        case .pink:
            return .highlight2
        case .green:
            return .highlight3
        case .blue:
            return .highlight4
        }
    }
    
    var uiColor: UIColor {
        return UIColor(self.color)
    }
}

struct HighlightColorButton: View {
    @Binding var button: HighlightColors?
    
    let selectedButton: HighlightColors
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 26, height: 26)
                
                Circle()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(selectedButton.color)
                    .overlay {
                        if button == selectedButton {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.gray700)
                        } else {
                            Circle()
                                .stroke(.primary4, lineWidth: 1)
                                .frame(width: 18, height: 18)
                        }
                    }
            }
        }
    }
}

struct WriteViewButton: View {
    @Binding var button: WriteButton?
    @Binding var HighlightColors: HighlightColors
    
    let buttonOwner: WriteButton
    let action: () -> Void
    
    var body: some View {
        let foregroundColor: Color = {
            if buttonOwner == .highlight {
                return button == .highlight ? HighlightColors.color : .gray800
            } else {
                return button == buttonOwner ? .gray100 : .gray800
            }
        }()
        
        Button(action: {
            action()
        }) {
            RoundedRectangle(cornerRadius: 6)
                .frame(width: 26, height: 26)
                .foregroundStyle(button == buttonOwner ? .primary1 : .clear)
                .overlay(
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
                            .frame(width: 26, height: 26)
                        
                        buttonOwner.icon
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(foregroundColor)
                            .frame(height: 18)
                    }
                )
        }
    }
}

// MARK: - Ver.2 Buttons
enum Buttons: String, CaseIterable {
    case drawing
    case comment
    case translate
    case lasso
    
    var icon: Image {
        switch self {
        case .drawing:
            return Image(systemName: "pencil.tip.crop.circle")
        case .comment:
            return Image(systemName: "text.bubble")
        case .translate:
            return Image(systemName: "globe")
        case .lasso:
            return Image(systemName: "square.dashed")
        }
    }
}

enum PenColors: String, CaseIterable {
    case black
    case red
    case blue
    case green
    
    var color: Color {
        switch self {
        case .black:
            return .gray800
        case .red:
            return .pen1
        case .blue:
            return .pen2
        case .green:
            return .pen3
        }
    }
    
    var uiColor: UIColor {
        return UIColor(self.color)
    }
}

struct ButtonsView: View {
    @Binding var button: Buttons?
    
    let selectedButton: Buttons
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(button == selectedButton ? .primary1 : .clear)
                .frame(width: 26, height: 26)
                .overlay(
                    selectedButton.icon
                        .font(.system(size: 16))
                        .foregroundStyle(button == selectedButton ? .gray100 : .gray800)
                )
        }
    }
}

struct PenColorButton: View {
    @Binding var button: PenColors?
    
    let selectedButton: PenColors
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 26, height: 26)
                
                Circle()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(selectedButton.color)
                    .overlay {
                        if button == selectedButton {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.primary4)
                        } else {
                            Circle()
                                .stroke(.primary4, lineWidth: 1)
                                .frame(width: 18, height: 18)
                        }
                    }
            }
        }
    }
}
