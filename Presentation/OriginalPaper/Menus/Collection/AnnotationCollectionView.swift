//
//  AnnotationCollectionView.swift
//  Reazy
//
//  Created by 문인범 on 1/31/25.
//

import SwiftUI


struct AnnotationCollectionView: View {
    var body: some View {
        Text("Hello World")
    }
}



struct AnnotationCollection: Identifiable, Equatable {
    let id: String

    let annotation: AnnotationCase
    let color: Color?
    let commenText: String?
    let contents: String
    
    enum AnnotationCase: Equatable {
        case Highlight
        case Comment
    }
}
