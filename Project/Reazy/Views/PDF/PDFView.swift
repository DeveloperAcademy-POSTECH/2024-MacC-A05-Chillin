//
//  PDFView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

struct PDFView: View {
  
  let index: Int
  
  var body: some View {
    Text("\(index)번째 문서")
  }
}

#Preview {
  PDFView(index: 1)
}
