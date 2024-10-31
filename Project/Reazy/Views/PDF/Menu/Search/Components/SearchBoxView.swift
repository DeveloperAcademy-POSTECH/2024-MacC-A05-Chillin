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
        
            // TODO: 그림자 수정
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 252)
                .foregroundStyle(.gray100)
                .shadow(radius: 0.5, x: 5, y: 5)
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
