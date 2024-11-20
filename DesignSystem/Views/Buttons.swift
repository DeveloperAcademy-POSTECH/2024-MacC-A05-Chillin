//
//  Buttons.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import SwiftUI

/// MainPDFView navigation bar 버튼
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

/// Highlight 관련 색상 선택 버튼
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

/// Pencil 관련 색상 선택 버튼
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

/// 폴더 색상 선택 버튼
enum FolderColors: String, CaseIterable {
    case folder1
    case folder2
    case folder3
    case folder4
    case folder5
    case folder6
    case folder7
    
    var color: Color {
        switch self {
        case .folder1:
            return Color(hex: "FB8F8F")
        case .folder2:
            return Color(hex: "EBCD7A")
        case .folder3:
            return Color(hex: "6CC3AF")
        case .folder4:
            return Color(hex: "4B9EC2")
        case .folder5:
            return Color(hex: "7C98E0")
        case .folder6:
            return Color(hex: "5F5DAA")
        case .folder7:
            return Color(hex: "EE7EAF")
        }
    }
    
    static func color(for rawValue: String) -> Color {
        return FolderColors(rawValue: rawValue)?.color ?? .primary1
    }
}

struct FolderColorButton: View {
    @Binding var button: FolderColors
    
    let selectedButton: FolderColors
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
                    .frame(width: 30, height: 30)
                
                Circle()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(selectedButton.color)
                    .overlay {
                        if button == selectedButton {
                            Circle()
                                .stroke(.gray100, lineWidth: 1.6)
                        }
                    }
            }
        }
    }
}
