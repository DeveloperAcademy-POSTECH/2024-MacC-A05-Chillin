//
//  PDFTagCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI


struct PDFTagCell<Tag: DynamicCell>: View {
    @State var isSelected: Bool = false
    @State var isAlertPresented: Bool = false
    let isMultiSelectable: Bool      // 멀티선택 가능 여부
    let isEditMode: Bool            // 편집 가능 여부
    
    let tag: Tag
    
    let selectAction: () -> Void
    let deleteAction: () -> Void
    
    var body: some View {
        Button {
            selectAction()
            if isMultiSelectable {
                isSelected.toggle()
            }
        } label: {
            // TODO: 태그 title
            HStack(spacing: 8) {
                Text(tag.name)
                    .reazyFont(isMultiSelectable ? .body1 : .h3)
                    .foregroundStyle(isSelected ? .gray300 : .gray800)
                    .frame(width: tag.getCellWidth())
                if isEditMode {
                    Button {
                        isAlertPresented = true
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundStyle(.gray700)
                            .font(.system(size: 12))
                    }
                    .alert("“\(tag.name)”\n태그를 삭제하시겠습니까?\n해당 태그가 달린 모든 논문에서도 삭제됩니다.", isPresented: $isAlertPresented) {
                        Button("삭제", role: .destructive, action: {
                            deleteAction()
                        })
                    }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(isSelected ? .point4 : .primary3)
            }
        }
    }
}

//#Preview {
//    HStack {
//        PDFTagCell(tag: TemporaryTag.init(name: "test")) {}
//        PDFTagCell(tag: TemporaryTag.init(name: "testfdas")) {}
//        PDFTagCell(tag: TemporaryTag.init(name: "testggggg")) {}
//        PDFTagCell(tag: TemporaryTag.init(name: "test")) {}
//        PDFTagCell(tag: TemporaryTag.init(name: "test")) {}
//    }
//}
