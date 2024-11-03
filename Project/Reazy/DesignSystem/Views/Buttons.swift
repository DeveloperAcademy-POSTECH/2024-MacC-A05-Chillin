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
  
  var icon: Image {
    switch self {
    case .comment:
      return Image(systemName: "text.bubble")
    case .highlight:
      return Image("Highlight")
    case .pencil:
      return Image("Pencil")
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
          buttonOwner.icon
            .resizable()
            .scaledToFit()
            .foregroundStyle(foregroundColor)
            .frame(height: 18)
        )
    }
  }
}
