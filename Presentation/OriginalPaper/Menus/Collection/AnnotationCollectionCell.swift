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
        VStack {
            if annotation.annotation == .comment {
                Text(annotation.commenText!)
            }
            
            Text(annotation.contents)
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
        contents: "테스트 컨텐츠입니다. 테스트 컨텐츠입니다.테스트 컨텐츠입니다.테스트 컨텐츠입니다.테스트 컨텐츠입니다."
    )
    
    let comment = AnnotationCollection(
        id: "",
        annotation: .comment,
        commenText: "테스트 코멘트 입니다.",
        contents: attributedString
    )
    
    return Group {
        AnnotationCollectionCell(annotation: highlight)
        AnnotationCollectionCell(annotation: comment)
    }
}
