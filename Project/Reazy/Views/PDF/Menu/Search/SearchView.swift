//
//  SearchView.swift
//  Reazy
//
//  Created by 문인범 on 10/29/24.
//

import SwiftUI


struct SearchView: View {
    @State private var text: String = ""
    
    var body: some View {
        VStack {
            ZStack {
                SearchBoxView()
                
                VStack {
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 232, height: 33)
                            .foregroundStyle(.gray.opacity(0.7))
                        
                        TextField("검색", text: $text)
                            .frame(width: 232, height: 33)
                    }
                    .padding(.top, 25)
                    
                    Spacer()
                }
            }
            .frame(height: text.isEmpty ? 79 : nil)
        }
    }
}
