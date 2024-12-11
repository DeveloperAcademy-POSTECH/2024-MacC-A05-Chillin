//
//  ConcentrateView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

// MARK: - 무니꺼 : 집중 모드 원문 뷰
struct ConcentrateView: View {
    @State private var textAlert: Bool = true
    
    
    var body: some View {
        VStack(spacing: 0) {
            ConcentrateViewControllerRepresent()
                .overlay(alignment: .top) {
                    if textAlert {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: 268, height: 40)
                                .foregroundStyle(.gray700)
                            
                            Text("집중 모드는 읽기 전용으로 제공됩니다")
                                .reazyFont(.h2)
                                .foregroundStyle(.gray100)
                        }
                        .padding(.top, 16)
                    }
                }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.textAlert = false
                }
            }
        }
    }
}

#Preview {
    ConcentrateView()
}
