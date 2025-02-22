//
//  PDFTagCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI


struct PDFTagCell<Tag: DynamicCell>: View {
    let tag: Tag
    
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            // TODO: 태그 title
            Text(tag.name)
                .reazyFont(.h3)
                .foregroundStyle(.gray800)
                .frame(height: 24)
                .padding(.horizontal, 8)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(.primary3)
                }
        }
    }
}
