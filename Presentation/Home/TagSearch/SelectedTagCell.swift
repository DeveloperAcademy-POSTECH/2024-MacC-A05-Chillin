//
//  SelectedTagCell.swift
//  Reazy
//
//  Created by 김예림 on 2/20/25.
//

import SwiftUI

struct SelectedTagCell<Tag: DynamicCell>: View {
    let tag: Tag
    let action: () -> Void
    let isBtnTapped: Bool
    
    var body: some View {
        HStack {
            Text(tag.name)
                .reazyFont(.text1)
                .foregroundStyle(isBtnTapped ? .gray300 : .gray800)

            if isBtnTapped {
                Button {
                    action()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray300)
                }
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(isBtnTapped ? .point4 : .primary3)
        }
    }
}
