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
        ScrollView {
            VStack {
                ForEach(viewModel.annotations) { annotation in
                    AnnotationCollectionCell(annotation: annotation)
                    
                    divider
                        .padding(.vertical, 16)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
        }
        .onAppear {
            viewModel.fetchData()
        }
    }
    
    
    private var divider: some View {
        Rectangle()
            .foregroundStyle(.gray500)
            .frame(height: 1)
    }
}
