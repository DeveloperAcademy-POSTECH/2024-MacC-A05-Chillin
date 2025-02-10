//
//  PDFTagCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI


struct PDFTagCell: View {
    var body: some View {
        Button {
            
        } label: {
            // TODO: 태그 title
            Text("Reazy")
                .reazyFont(.body1)
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
