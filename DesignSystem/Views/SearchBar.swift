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
                Image(.search)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.gray600)
                
                TextField("검색", text: $text)
                    .foregroundStyle(.gray600)
                    .onSubmit {
                        setRecentSearchList()
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                        
                    })
                }
            }
            .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            .foregroundStyle(.secondary)
            .background(.primary2)
            .cornerRadius(10.0)
        }
        .padding(.horizontal)
    }
    
    private func setRecentSearchList() {
        var current = UserDefaults.standard.recentSearches
        
        if current.count == 30 {
            current.removeFirst()
        }
        
        current.append(self.text)
    }
}

#Preview {
    SearchBar(text: .constant(""))
}
