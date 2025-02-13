//
//  PDFTagCell.swift
//  Reazy
//
//  Created by 문인범 on 2/10/25.
//

import SwiftUI


struct PDFTagCell: View {
    let tag: any DynamicCell
    
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            // TODO: 태그 title
            Text(tag.name)
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

#Preview {
    HStack {
        PDFTagCell(tag: TemporaryTag.init(name: "test")) {}
        PDFTagCell(tag: TemporaryTag.init(name: "testfdas")) {}
        PDFTagCell(tag: TemporaryTag.init(name: "testggggg")) {}
        PDFTagCell(tag: TemporaryTag.init(name: "test")) {}
        PDFTagCell(tag: TemporaryTag.init(name: "test")) {}
    }
}

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
