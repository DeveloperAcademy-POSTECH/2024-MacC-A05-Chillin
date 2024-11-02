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
                .foregroundStyle(.gray100)
                .offset(y: -5)
        }
        .background {
            Color.white
                .cornerRadius(12)
                .shadow(color:Color(hex: "6A6A6A").opacity(0.1), radius: 16)
                .padding(.vertical, 5)
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


#Preview {
    SearchBoxView()
}
