//
//  FigureCell.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI
import Foundation


// MARK: - Lucid : FigureView 커스텀 리스트 셀
struct FigureCell: View {
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray)
                .frame(height: 152)
                .padding(.bottom, 10)
            
            Text("Fig 3.1")
                .font(.system(size: 12))
        }
    }
}


#Preview {
    FigureCell()
}
