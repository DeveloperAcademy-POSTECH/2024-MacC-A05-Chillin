//
//  AnnotationCollection.swift
//  Reazy
//
//  Created by 문인범 on 2/1/25.
//

import Foundation


struct AnnotationCollection: Identifiable, Equatable {
    let id: String

    let annotation: AnnotationCase
    let commenText: String?
    let contents: AttributedString
    let pageIndex: Int
    
    enum AnnotationCase: Equatable {
        case highlight
        case comment
    }
}
