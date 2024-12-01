//
//  BubbleViewOlderVer.swift
//  Reazy
//
//  Created by Minjung Lee on 10/31/24.
//

import SwiftUI

struct TranslateViewOlderVer: View {

    var body: some View {
        // 18.0 미만 버전에서 보여줄 화면
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray200)
                .stroke(.primary3, lineWidth: 1)
                .frame(width: 400, height: 77)
                .shadow(color: Color(hex: "#767676").opacity(0.25), radius: 6, x: 0, y: 2)
            VStack(alignment: .center) {
                Text("해당 번역 기능은 iPadOS 18.0 이상에서만 사용 가능합니다.\niPadOS 18.0 미만 버전에서는 소프트웨어 업데이트가 필요합니다.")
                    .reazyFont(.body2)
                    .foregroundColor(.point2)
                    .lineSpacing(3)
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
        }
        .offset(y: 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 화면 중간 상단에 고정
    }
}
