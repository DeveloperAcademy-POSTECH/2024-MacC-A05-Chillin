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
            return 200
        case "comment":
            return 230
        case "lasso":
            return 250
        default:
            return 200
        }
    }
    
    private var alertMessage: String {
        switch mode {
        case "translate":
            return "번역할 텍스트를 드래그하세요"
        case "comment":
            return "코멘트를 남길 부분을 드래그하세요"
        case "lasso":
            return "추가할 figure 영역을 드래그하세요"
        default:
            return ""
        }
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: alertWidth, height: 40)
                    .foregroundStyle(.gray700)
                
                Text(alertMessage)
                    .foregroundStyle(.gray100)
                    .reazyFont(.button2)
            }
        }
        .onAppear {
            isPresented = true
        }
        .offset(y: 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
