//
//  ShapeStyle+Color.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

extension ShapeStyle where Self == Color {
  static var primary1: Color { Color(hex: "5F5DAA") }
  static var primary2: Color { Color(hex: "E4E6F3") }
  static var primary3: Color { Color(hex: "DADDEF") }
  static var primary4: Color { Color(hex: "CCCEE1") }
  
  static var point1: Color { Color(hex: "05043E") }
  static var point2: Color { Color(hex: "26235D") }
  static var point3: Color { Color(hex: "D2CFFF") }
  
  static var gray900: Color { Color(hex: "3C3D4B") }
  static var gray800: Color { Color(hex: "636577") }
  static var gray700: Color { Color(hex: "636577") }
  static var gray600: Color { Color(hex: "9092A9") }
  static var gray500: Color { Color(hex: "D2D4E5") }
  static var gray400: Color { Color(hex: "DDDFEC") }
  static var gray300: Color { Color(hex: "EFEFF8") }
  static var gray200: Color { Color(hex: "F7F7FB") }
  static var gray100: Color { Color(hex: "FFFFFF") }
}

extension UIColor {
    static var primary1: UIColor { UIColor(hex: "5F5DAA") }
    static var primary2: UIColor { UIColor(hex: "E4E6F3") }
    static var primary3: UIColor { UIColor(hex: "DADDEF") }
    static var primary4: UIColor { UIColor(hex: "CCCEE1") }
    
    static var point1: UIColor { UIColor(hex: "05043E") }
    static var point2: UIColor { UIColor(hex: "26235D") }
    static var point3: UIColor { UIColor(hex: "D2CFFF") }
    
    static var gray900: UIColor { UIColor(hex: "3C3D4B") }
    static var gray800: UIColor { UIColor(hex: "636577") }
    static var gray700: UIColor { UIColor(hex: "636577") }
    static var gray600: UIColor { UIColor(hex: "9092A9") }
    static var gray500: UIColor { UIColor(hex: "D2D4E5") }
    static var gray400: UIColor { UIColor(hex: "DDDFEC") }
    static var gray300: UIColor { UIColor(hex: "EFEFF8") }
    static var gray200: UIColor { UIColor(hex: "F7F7FB") }
    static var gray100: UIColor { UIColor(hex: "FFFFFF") }
}

extension Color {
  init(hex: String) {
    let scanner = Scanner(string: hex)
    _ = scanner.scanString("#")
    
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)
    
    let r = Double((rgb >> 16) & 0xFF) / 255.0
    let g = Double((rgb >>  8) & 0xFF) / 255.0
    let b = Double((rgb >>  0) & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}

extension UIColor {
  convenience init(hex: String) {
    let scanner = Scanner(string: hex)
    _ = scanner.scanString("#")
    
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)
    
    let r = Double((rgb >> 16) & 0xFF) / 255.0
    let g = Double((rgb >>  8) & 0xFF) / 255.0
    let b = Double((rgb >>  0) & 0xFF) / 255.0
    
    self.init(red: r, green: g, blue: b, alpha: 1)
  }
}

