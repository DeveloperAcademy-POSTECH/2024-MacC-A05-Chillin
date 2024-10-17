//
//  OriginalView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

// MARK: - 무니꺼 : 원문 모드 뷰
struct OriginalView: View {
    @EnvironmentObject private var viewModel: OriginalViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            OriginalViewControllerRepresent()
        }
    }
}
    
#Preview {
    OriginalView()
}
