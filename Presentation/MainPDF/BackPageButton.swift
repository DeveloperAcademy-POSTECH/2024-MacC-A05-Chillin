//
//  PreviousButton.swift
//  Reazy
//
//  Created by 김예림 on 1/25/25.
//

import SwiftUI

struct BackPageButton: View {
    
    @EnvironmentObject private var viewModel: MainPDFViewModel
    
    var body: some View {
        Button(action: {
            viewModel.isLinkTapped = false
            
            print("버튼 누르기 전 : \(viewModel.backPageDestination)")
            viewModel.updateBackDestination()
            print("버튼 누른 후 : \(viewModel.backPageDestination)")
        }, label: {
            HStack {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12))
                    .padding(.trailing, 4)
                
                Text("이전 페이지로")
                    .reazyFont(.body3)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 13)
            .foregroundStyle(.gray100)
            .background(
                Color(.gray700)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )
        })
    }
}

#Preview {
    BackPageButton()
}
