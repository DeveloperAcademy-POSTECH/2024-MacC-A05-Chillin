//
//  Array.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

extension Array where Element == Bool {
  
  // isSelected Bool 배열 중 한 가지만 true
  mutating func toggleSelection(at index: Int) {
    for i in 0..<self.count {
      self[i] = (i == index)
    }
  }
}
