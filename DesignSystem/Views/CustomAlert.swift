//
//  CustomAlert.swift
//  Reazy
//
//  Created by 김예림 on 3/6/25.
//

import SwiftUI

struct CustomAlert: View {
    let mainText: String
    let message: String?
    let width: CGFloat
    let height: CGFloat
    
    let cancleAction: () -> Void
    let confirmAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .center, spacing: 0) {
                Text(mainText)
                    .reazyFont(.button1)
                    .foregroundStyle(.gray900)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 2)
                if let message = message {
                    Text(message)
                        .reazyFont(.body1)
                        .foregroundStyle(.gray900)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 30)
            Spacer()
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray400)
            
            HStack(spacing: 70) {
                Button {
                    cancleAction()
                } label: {
                    Text("취소")
                        .reazyFont(.text1)
                }
                Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(.gray400)
                Button {
                    confirmAction()
                } label: {
                    Text("삭제")
                        .reazyFont(.text1)
                        .foregroundStyle(.pen1)
                }
            }
            .frame(height: 52)
        }
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray200)
        )
        
    }
}
