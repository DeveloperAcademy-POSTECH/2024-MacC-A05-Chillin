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
        VStack(alignment: .leading) {
            MenuCell(icon: "copyLight", title: "복사하기", action: onCopy)
//            {
//                UIPasteboard.general.string = viewModel.selectedText
//            }
            
            Divider()
            
            MenuCell(icon: nil, title: "Google Scholar 검색", action: onSearchScholar)
            MenuCell(icon: nil, title: "하이라이트", action: onHighlight)
            MenuCell(icon: nil, title: "코멘트", action: onComment)
            
            Divider()
            
            MenuCell(icon: "share", title: "공유", action: onShare)
        }
        .padding()
        .foregroundStyle(.gray200)
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
            HStack(spacing: 8) {
                Image(icon ?? "")
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 17)
                    .foregroundStyle(.gray800)
                Text(title)
                    .reazyFont(.body1)
                    .foregroundStyle(.gray800)
            }
        }
    }
}
#Preview {
//    TextEditMenu()
}
