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
    
    let action: () -> Void
    
    init(name: String) {
        self.tag = nil
        self.name = name
        self.action = {}
    }
    
    init(tag: Tag, action: @escaping () -> Void) {
        self.tag = tag
        self.name = tag.name
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
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
}
