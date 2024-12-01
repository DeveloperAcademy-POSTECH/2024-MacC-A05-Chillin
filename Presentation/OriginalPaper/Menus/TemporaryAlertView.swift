//
//  TemporaryAlertView.swift
//  Reazy
//
//  Created by Minjung Lee on 11/22/24.
//

import SwiftUI

struct TemporaryAlertView: View {
    @State var isPresented = false
    @State var mode: String
    
    private var alertWidth: CGFloat {
        switch mode {
        case "translate":
            return 235
        case "comment":
            return 255
        case "lasso":
            return 250
        default:
            return 250
        }
    }
    
    private var alertMessage: String {
        switch mode {
        case "translate":
            return "번역할 텍스트를 꾹 눌러 선택하세요"
        case "comment":
            return "코멘트를 남길 부분을 꾹 눌러 선택하세요"
        case "lasso":
            return "추가할 figure 영역을 드래그하세요"
        default:
            return ""
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isPresented {
                    RoundedRectangle(cornerRadius: 12)
                        .frame(width: alertWidth, height: 40)
                        .foregroundStyle(.gray700)
                        .position(x: geometry.size.width / 2, y: 100)
                    
                    Text(alertMessage)
                        .foregroundStyle(.gray100)
                        .reazyFont(.button2)
                        .position(x: geometry.size.width / 2, y: 100)
                }
            }
            .onAppear {
                isPresented = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPresented = false
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
