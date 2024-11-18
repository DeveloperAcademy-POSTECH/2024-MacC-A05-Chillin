//
//  FolderListCell.swift
//  Reazy
//
//  Created by 유지수 on 11/18/24.
//

import SwiftUI

struct FolderListCell: View {
    
    let title: String
    let createdAt: String
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
                    .foregroundStyle(color)
                    .overlay(
                        Image(systemName: "folder.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray100)
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .lineLimit(1)
                        .reazyFont(.h2)
                        .foregroundStyle(.gray800)
                        .padding(.bottom, 6)
                    Text(createdAt)
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
    FolderListCell(
        title: "저널 클럽 1주차",
        createdAt: "오늘 오후 07:23",
        color: .primary1,
        isSelected: false,
        isEditing: false,
        isEditingSelected: false,
        onSelect: {},
        onEditingSelect: {}
    )
}
