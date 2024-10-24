//
//  Buttons.swift
//  Reazy
//
//  Created by 유지수 on 10/24/24.
//

import SwiftUI

enum WriteButton: String, CaseIterable {
  case comment
  case highlight
  case pencil
  case eraser
  case translate
  
  var icon: String {
    switch self {
    case .comment:
      "text.bubble"
    case .highlight:
      "highlighter"
    case .pencil:
      "scribble"
    case .eraser:
      "eraser"
    case .translate:
      "character.square"
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
      return Color(hex: "FEF166")
    case .pink:
      return Color(hex: "F799D1")
    case .green:
      return Color(hex: "7DF066")
    case .blue:
      return Color(hex: "8FDEF9")
    }
  }
}

struct ColorButton: View {
  @Binding var button: HighlightColors
  
  let buttonOwner: HighlightColors
  let action: () -> Void
  
  var body: some View {
    Button(action: {
      action()
    }) {
      Circle()
        .frame(width: 18, height: 18)
        .foregroundStyle(buttonOwner.color)
        .overlay(
          Image(systemName: "checkmark.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundStyle(buttonOwner == button ? .gray700 : .clear)
        )
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
          Image(systemName: buttonOwner.icon)
            .resizable()
            .scaledToFit()
            .foregroundStyle(foregroundColor)
            .frame(height: 18)
        )
    }
  }
}
