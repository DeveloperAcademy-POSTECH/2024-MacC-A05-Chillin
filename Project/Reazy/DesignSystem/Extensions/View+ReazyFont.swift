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
    case h5
    
    case button1
    case button2
    case button3
    case button4
    case button5
    
    case text1
    case text2
    case text3
    case text4
    case text5
    
    case body1
    case body2
    case body3
    
    static let pretendardBoldFont: String = "Pretendard-Bold"
    static let pretendardMediumFont: String = "Pretendard-Medium"
    static let pretendardRegularFont: String = "Pretendard-Regular"
    static let pretendardSemiboldFont: String = "Pretendard-SemiBold"
    
    
    var fontSize: CGFloat {
        switch self {
        case .text4: return 10
        case .button4, .button5, .text2, .text5, .body3: return 12
        case .h3, .h4, .button2, .button3, .body1, .body2: return 14
        case .h2, .text3: return 15
        case .text1, .button1: return 16
        case .h5: return 20
        case .h1: return 24
        }
    }
    
    var lineHeight: CGFloat {
        switch self {
        case .text4: return 12
        case .button4, .button5, .text5: return 14
        case .text2: return 16
        case .h3, .button3: return 17
        case .h4, .body3: return 18
        case .h2, .button2, .text1, .text3, .body1, .body2: return 20
        case .button1: return 23
        case .h1, .h5: return 34
        }
    }
    
    var fontWeight: String {
        switch self {
        case .h1, .h5, .button1, .button2: return ReazyFontType.pretendardSemiboldFont
        case .h2, .h3, .button5, .text1, .body1, .body3: return ReazyFontType.pretendardMediumFont
        case .h4, .button3, .text2, .text4, .text5, .body2: return ReazyFontType.pretendardRegularFont
        case .button4, .text3: return ReazyFontType.pretendardBoldFont
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

/// UIKit 용
extension UIFont {
    static func reazyFont(_ type: ReazyFontType) -> UIFont {
        return UIFont(name: type.fontWeight, size: type.fontSize) ?? .systemFont(ofSize: type.fontSize)
    }
    
    static func reazyManualFont(_ type: ReazyUIFontType, size: CGFloat) -> UIFont {
        UIFont(name: type.rawValue , size: size) ?? .systemFont(ofSize: size)
    }
    
    enum ReazyUIFontType: String {
        case bold = "Pretendard-Bold"
        case medium = "Pretendard-Medium"
        case regular = "Pretendard-Regular"
        case semibold = "Pretendard-SemiBold"
    }
}
