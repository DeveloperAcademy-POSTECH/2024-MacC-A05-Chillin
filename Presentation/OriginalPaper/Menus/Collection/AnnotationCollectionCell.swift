//
//  AnnotationCollectionCell.swift
//  Reazy
//
//  Created by 문인범 on 1/31/25.
//

import SwiftUI


struct AnnotationCollectionCell: View {
    let annotation: AnnotationCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if annotation.annotation == .comment {
                HStack(spacing: 0) {
                    Rectangle()
                        .foregroundStyle(.point4)
                        .frame(width: 1, height: 35)
                        .padding(.trailing, 8)
                    
                    Text(annotation.commenText ?? "알 수 없음")
                        .font(.custom(ReazyFontType.pretendardMediumFont, size: 12))
                        .foregroundStyle(.point4)
                        .lineSpacing(5)
                        .lineLimit(2)
                }
                .padding(.bottom, 8)
            }
            
            Text(annotation.contents)
                .lineSpacing(5)
                .lineLimit(9)
        }
    }
}



#Preview {
    var attributedString = AttributedString(stringLiteral: "테스트 컨텐츠입니다. 테스트 컨텐츠입니다.테스트 컨텐츠입니다.테스트 컨텐츠입니다.테스트 컨텐츠입니다.")
    
    let attributes: AttributeContainer = .init([
        .backgroundColor: UIColor.red,
        .font: UIFont.init(name: ReazyFontType.pretendardRegularFont, size: 12)!,
    ])
    
    attributedString.setAttributes(attributes)
    
    let highlight = AnnotationCollection(
        id: "",
        annotation: .highlight,
        commenText: nil,
        contents: attributedString
    )
    
    let comment = AnnotationCollection(
        id: "",
        annotation: .comment,
        commenText: "테스트 코멘트 입니다.테스트 코멘트 입니다.",
        contents: "테스트 컨텐츠입니다. 테스트 컨텐츠입니다.테스트 컨텐츠입니다.테스트 컨텐츠입니다.테스트 컨텐츠입니다."
    )
    
    return Group {
        AnnotationCollectionCell(annotation: highlight)
        Divider()
        AnnotationCollectionCell(annotation: comment)
    }
}
