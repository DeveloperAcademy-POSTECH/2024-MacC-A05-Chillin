//
//  AnnotationCollectionView.swift
//  Reazy
//
//  Created by 문인범 on 1/31/25.
//

import SwiftUI


struct AnnotationCollectionView: View {
    @StateObject private var viewModel: AnnotationCollectionViewModel = .init()
    
    var body: some View {
        List {
            ForEach(viewModel.annotations) { annotation in
                AnnotationCollectionCell(annotation: annotation)
            }
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
}
