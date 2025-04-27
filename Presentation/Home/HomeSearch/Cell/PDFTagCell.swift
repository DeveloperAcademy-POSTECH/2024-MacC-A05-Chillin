//
//  PDFTagCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI


struct PDFTagCell<Tag: DynamicCell>: View {
    @State private var isAlertPresented: Bool = false
    let isMultiSelectable: Bool      // 멀티선택 가능 여부
    let isEditMode: Bool            // 편집 가능 여부

    var tag: Tag
    
    let selectAction: () -> Void
    let deleteAction: () -> Void
    
    var body: some View {
        Button {
            if !isEditMode {
                selectAction()
            }
        } label: {
            // TODO: 태그 title
            HStack(spacing: 0) {
                Text(tag.name)
                    .reazyFont(isMultiSelectable ? .body1 : .h3)
                    .foregroundStyle(tag.isSelected ? .gray300 : .gray800)
                    .fixedSize(horizontal: true, vertical: false)
                
                // 삭제 버튼
                if isEditMode {
                    Spacer().frame(width: 4)
                    Button {
                        deleteAction()
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundStyle(.gray700)
                            .font(.system(size: 12))
                    }
                }
            }
            .frame(height: 24)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(tag.isSelected ? .point4 : .primary3)
            }
        }
    }
}
