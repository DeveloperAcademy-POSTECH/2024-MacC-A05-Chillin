//
//  SearchBoxView.swift
//  Reazy
//
//  Created by 문인범 on 10/29/24.
//

import SwiftUI


struct SearchBoxView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedCornerTriangleView()
                .frame(width: 46, height: 10)
        
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 252)
                .foregroundStyle(Color(uiColor: .systemGreen))
        }
    }
}


private struct RoundedCornerTriangleView: UIViewRepresentable {
    func makeUIView(context: Context) -> RoundedCornerTriangle {
        .init()
    }
    
    func updateUIView(_ uiView: RoundedCornerTriangle, context: Context) {
        
    }
}
