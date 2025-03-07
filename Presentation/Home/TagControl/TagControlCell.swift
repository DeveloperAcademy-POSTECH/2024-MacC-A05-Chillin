//
//  TagControlCell.swift
//  Reazy
//
//  Created by 문인범 on 3/7/25.
//

import SwiftUI


struct TagControlCell: View {
    let tag: Tag?
    let name: String
    
    init(tag: Tag? = nil, name: String) {
        self.tag = tag
        self.name = name
    }
    
    var body: some View {
        Text(tag?.name ?? name)
            .reazyFont(.body3)
            .foregroundStyle(.gray800)
            .frame(height: 28)
            .padding(.horizontal, 9)
            .background {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(.primary3)
            }
    }
}
