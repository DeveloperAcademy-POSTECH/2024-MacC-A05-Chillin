//
//  SearchBar.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI

struct SearchBar: View {
  
  @Binding var text: String
  
  var body: some View {
    HStack {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.gray600)
        
        TextField("검색", text: $text)
          .foregroundStyle(.gray600)
        
        if !text.isEmpty {
          Button(action: {
            self.text = ""
          }, label: {
            Image(systemName: "xmark.circle.fill")
          })
          .id(text)
          .transition(.opacity)
          .animation(.easeInOut(duration: 0.2), value: text)
        } else {
          EmptyView()
        }
      }
      .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
      .foregroundStyle(.secondary)
      .background(.primary2)
      .cornerRadius(10.0)
    }
    .padding(.horizontal)
  }
}

#Preview {
  SearchBar(text: .constant(""))
}
