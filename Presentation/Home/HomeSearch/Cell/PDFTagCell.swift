//
//  PDFTagCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI


struct PDFTagCell<Tag: DynamicCell>: View {
    @EnvironmentObject var tagViewModel: TagViewModel
    var isSelected: Bool {
        isMultiSelectable && tagViewModel.selectedTags.contains(tag.name)
    }
    let isMultiSelectable: Bool      // 멀티선택 가능 여부
    
    let tag: Tag
    
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            // TODO: 태그 title
            HStack(spacing: 8) {
                Text(tag.name)
                    .reazyFont(.h3)
                    .foregroundStyle(isSelected ? .gray300 : .gray800)
                    .frame(width: tag.getCellWidth())
                if tagViewModel.isEditMode {
                    Button {
                        tagViewModel.deleteTag(id: tag.id)
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundStyle(.gray700)
                            .font(.system(size: 12))
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

// TODO: 추후 엔티티 수정 및 폴더링 예정
struct TemporaryTag: DynamicCell {
    let id = UUID()
    let name: String
    
    public func getCellWidth() -> CGFloat {
        let count = self.name.count
        return CGFloat(10 + count * 10)
    }
}


protocol DynamicCell: Hashable, Identifiable {
    var id: UUID { get }
    var name: String { get }
    
    func getCellWidth() -> CGFloat
}

extension DynamicCell {
    /// 편집 모드 여부에 따라 동적으로 셀 너비를 계산
    func itemWidth(isEditMode: Bool) -> CGFloat {
        let additionalPadding: CGFloat = isEditMode ? 40 : 16
        return getCellWidth() + additionalPadding
    }
}
