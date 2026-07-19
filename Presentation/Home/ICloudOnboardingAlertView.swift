//
//  ICloudOnboardingAlertView.swift
//  Reazy
//
//  Created by Claude on 7/19/26.
//

import SwiftUI

struct ICloudOnboardingAlertView: View {
    @State private var useICloud: Bool = true
    let completeAction: (Bool) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 21.47)
                .foregroundStyle(.gray200)

            VStack(spacing: 0) {
                Text("iCloud와 동기화하시겠습니까?")
                    .reazyFont(.button1)
                    .padding(.top, 30)

                Toggle("iCloud 사용", isOn: $useICloud)
                    .padding(.horizontal, 30)
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                seperator

                Button {
                    completeAction(self.useICloud)
                } label: {
                    Text("확인")
                        .reazyFont(.text1)
                        .foregroundStyle(.primary1)
                        .frame(width: 460)
                        .padding(.vertical, 20)
                }
            }
        }
        .frame(width: 464, height: 210)
    }

    private var seperator: some View {
        Rectangle()
            .foregroundStyle(Color(hex: "#D9DBE9"))
            .frame(height: 1)
    }
}
