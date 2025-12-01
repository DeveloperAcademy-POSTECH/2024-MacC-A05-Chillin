//
//  CustomAlert.swift
//  Reazy
//
//  Created by 김예림 on 3/6/25.
//

import SwiftUI

struct CustomAlert: View {
    var type: AlertType
    
    let mainText: String
    let message: String?
    let width: CGFloat
    let height: CGFloat
    
    let cancelAction: () -> Void
    let confirmAction: () -> Void
    
    init(
        type: AlertType = .delete,
        mainText: String,
        message: String? = nil,
        width: CGFloat,
        height: CGFloat,
        cancelAction: @escaping () -> Void,
        confirmAction: @escaping () -> Void = {}
    ) {
        self.type = type
        self.mainText = mainText
        self.message = message
        self.width = width
        self.height = height
        self.cancelAction = cancelAction
        self.confirmAction = confirmAction
    }
    
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
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 30)
            Spacer()
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray400)
            
            HStack(spacing: 0) {
                buttonGroup(for: type)
            }
            .frame(height: 52)
        }
        .frame(width: width, height: height)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray200)
        )
        
    }
    
    @ViewBuilder
    private func buttonGroup(for type: AlertType) -> some View {
        switch type {
        case .confirm:
            Button(action: cancelAction) {
                Text("확인")
                    .reazyFont(.text1)
                    .frame(width: self.width, height: 50)
            }

        case .delete:
            Button(action: cancelAction) {
                Text("취소")
                    .reazyFont(.text1)
                    .frame(width: self.width/2, height: 50)
            }

            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.gray400)
            
            Button(action: confirmAction) {
                Text("삭제")
                    .reazyFont(.text1)
                    .foregroundStyle(.pen1)
                    .frame(width: self.width/2, height: 50)
            }
        }
    }

}


enum AlertType {
    case confirm, delete
}
