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
            HStack(spacing: 0) {
                Button {
                    homeSearchViewModel.searchTargetChanged(target: .title)
                } label: {
                    Text("제목")
                        .reazyFont(.button1)
                        .foregroundStyle(
                            homeSearchViewModel.searchTarget == .title ? .primary1 : .gray550
                        )
                        .padding(.leading, 30)
                        .padding(.trailing, 20)
                }
                
                Button {
                    homeSearchViewModel.searchTargetChanged(target: .tag)
                } label: {
                    Text("태그")
                        .reazyFont(.button1)
                        .foregroundStyle(
                            homeSearchViewModel.searchTarget == .tag ? .primary1 : .gray550
                        )
                        .padding(.leading, 20)
                        .padding(.vertical, 20)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            
            if homeSearchViewModel.searchList.isEmpty {
                Spacer()
                SearchResultEmptyView(text: homeSearchViewModel.searchText)
                Spacer()
            } else {
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
}


private struct SearchResultEmptyView: View {
    let text: String
    
    var body: some View {
        Text("\"\(text)\"와\n일치하는 결과가 없어요")
            .reazyFont(.h5)
            .foregroundStyle(.gray550)
            .multilineTextAlignment(.center)
    }
}


#Preview {
    HomeSearchView()
}
