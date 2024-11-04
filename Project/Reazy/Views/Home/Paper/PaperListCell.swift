//
//  PaperListCell.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

struct PaperListCell: View {
    
    let title: String
    let date: String
    let isSelected: Bool
    let isEditing: Bool
    let isEditingSelected: Bool
    let onSelect: () -> Void
    let onEditingSelect: () -> Void
    
    var body: some View {
        ZStack {
            if isSelected && !isEditing {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.primary2)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 8)
            }
            
            HStack(spacing: 0) {
                if isEditing {
                    Image(systemName: isEditingSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isEditingSelected ? .primary1 : .primary4)
                        .onTapGesture {
                            onEditingSelect()
                        }
                        .padding(.trailing, 20)
                }
                
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 42, height: 42)
                    .foregroundStyle(.gray500)
                    .overlay(
                        Image("document")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 21)
                            .foregroundStyle(.gray100)
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .lineLimit(2)
                        .reazyFont(.h2)
                        .foregroundStyle(.gray900)
                        .padding(.bottom, 6)
                    Text(date)
                        .reazyFont(.h4)
                        .foregroundStyle(.gray600)
                }
                .padding(.leading, 15)
                
                Spacer()
            }
            .background(.clear)
            .padding(.horizontal, 22)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditing {
                    onEditingSelect()
                } else {
                    onSelect()
                }
            }
        }
    }
}

#Preview {
    PaperListCell(
        title: "test",
        date: "1시간 전",
        isSelected: false,
        isEditing: true,
        isEditingSelected: false,
        onSelect: {},
        onEditingSelect: {}
    )
}
