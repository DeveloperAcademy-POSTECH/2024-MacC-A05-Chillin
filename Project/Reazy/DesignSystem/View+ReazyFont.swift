//
//  View+ReazyFont.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import UIKit

public enum ReazyFontType {
  case h1
  case h2
  case h3
  case h4
  
  case button1
  case button2
  case button3
  case button4
  case button5
  
  case text1
  case text2
  
  static let pretendardBoldFont: String = "Pretendard-Bold"
  static let pretendardMediumFont: String = "Pretendard-Medium"
  static let pretendardRegularFont: String = "Pretendard-Regular"
  static let pretendardSemiboldFont: String = "Pretendard-SemiBold"
  
  
  var fontSize: CGFloat {
    switch self {
    case .button4, .button5, .text2: return 12
    case .text1: return 13
    case .h3, .h4, .button2, .button3: return 14
    case .h2: return 15
    case .button1: return 16
    case .h1: return 24
    }
  }
  
  var lineHeight: CGFloat {
    switch self {
    case .button4, .button5: return 0
    case .text2: return 16
    case .h3, .button3: return 17
    case .h4, .text1: return 18
    case .h2, .button2: return 20
    case .button1: return 23
    case .h1: return 34
    }
  }
  
  var fontWeight: String {
    switch self {
    case .h1, .button1, .button2: return ReazyFontType.pretendardSemiboldFont
    case .h2, .h3, .button5, .text1: return ReazyFontType.pretendardMediumFont
    case .h4, .button3, .text2: return ReazyFontType.pretendardRegularFont
    case .button4: return ReazyFontType.pretendardBoldFont
    }
  }
}

extension View {
  func reazyFont(_ type: ReazyFontType) -> some View {
    let font = UIFont(name: type.fontWeight, size: type.fontSize) ?? UIFont.systemFont(ofSize: type.fontSize)
    
    return self
      .font(Font(font))
      .lineSpacing(type.lineHeight - font.lineHeight)
      .padding(.vertical, (type.lineHeight - font.lineHeight) / 2)
  }
}
