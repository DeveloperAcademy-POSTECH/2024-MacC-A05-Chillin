//
//  HomeSearchView.swift
//  Reazy
//
//  Created by 문인범 on 2/12/25.
//

import SwiftUI


struct HomeSearchView: View {
    @EnvironmentObject private var homeSearchViewModel: HomeSearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // TODO: 제목 or 태그 버튼으로 구현
            HStack(spacing: 0) {
                Text("제목")
                    .reazyFont(.button1)
                    .foregroundStyle(.primary1)
                    .padding(.leading, 30)
                
                Text("태그")
                    .reazyFont(.button1)
                    .foregroundStyle(.gray550)
                    .padding(.leading, 40)
                
                Spacer()
            }
            .padding(.vertical, 20)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(homeSearchViewModel.searchList) { paperInfo in
                        HomePDFCell(paperInfo: paperInfo)
                        
                        Rectangle()
                            .foregroundStyle(.primary3)
                            .frame(height: 1)
                    }
                    .padding(.leading, 30)
                }
            }
        }
    }
}


#Preview {
    HomeSearchView()
}
