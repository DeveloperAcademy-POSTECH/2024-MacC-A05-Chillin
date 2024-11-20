//
//  PaperListCell.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

struct PaperListCell: View {
    let isPaper: Bool
    
    let title: String
    let date: String
    let color: Color
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
                    .foregroundStyle(isPaper ? .gray500 : color)
                    .overlay(
                        Image(isPaper ? "document" : "folder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .lineLimit(1)
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
        isPaper: true,
        title: "test",
        date: "1시간 전",
        color: .gray500,
        isSelected: false,
        isEditing: true,
        isEditingSelected: false,
        onSelect: {},
        onEditingSelect: {}
    )
}
