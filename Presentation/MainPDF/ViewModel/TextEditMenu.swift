//
//  TextEditMenu.swift
//  Reazy
//
//  Created by 김예림 on 2/24/26.
//

import SwiftUI

struct TextEditMenu: View {
    
    let onCopy: () -> Void
    let onSearchScholar: () -> Void
    let onHighlight: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuCell(icon: "copyLight", title: "복사하기", action: onCopy)
                .padding(.horizontal, 17)
                .padding(.vertical, 13)
            
            Rectangle()
                .fill(Color.primary2)
                .frame(height: 1)
            
            VStack(alignment: .leading, spacing: 13) {
                MenuCell(icon: nil, title: "Google Scholar 검색", action: onSearchScholar)
                MenuCell(icon: nil, title: "하이라이트", action: onHighlight)
                MenuCell(icon: nil, title: "코멘트", action: onComment)
            }
            .padding(.horizontal, 17)
            .padding(.vertical, 13)
            
            Rectangle()
                .fill(Color.primary2)
                .frame(height: 1)
            
            MenuCell(icon: "share", title: "공유", action: onShare)
                .padding(.horizontal, 17)
                .padding(.vertical, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray200)
        )
        .fixedSize()
    }
}


private struct MenuCell: View {
    let icon: String?
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 0) {
                if let icon {
                    Image(icon)
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 17)
                        .foregroundStyle(.gray800)
                        .padding(.trailing, 8)
                }
                Text(title)
                    .reazyFont(.body1)
                    .foregroundStyle(.gray800)
                
                Spacer()
            }
            .padding(0)
        }
    }
}
#Preview {
//    TextEditMenu()
}
