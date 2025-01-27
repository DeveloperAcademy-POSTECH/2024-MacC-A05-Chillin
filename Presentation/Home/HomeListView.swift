//
//  HomeListView.swift
//  Reazy
//
//  Created by 유지수 on 1/27/25.
//

import SwiftUI

struct HomeListView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var isMainSelected: Bool = true
    @State private var isFavoriteSelected: Bool = false
    @State private var isTagSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isMainSelected ? Color(hex: "EFEFF8") : .clear)
                    .frame(height: 43)
                    .overlay {
                        HStack(spacing: 0) {
                            Image(systemName: isMainSelected ? "text.page.fill" : "text.page")
                                .font(.system(size: 18))
                                .foregroundStyle(isMainSelected ? .primary1 : .gray700)
                                .padding(.trailing, 11)
                            
                            Text("전체")
                                .reazyFont(isMainSelected ? .button1 : .text1)
                                .foregroundStyle(isMainSelected ? .primary1 : .gray700)
                            
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                    .onTapGesture {
                        self.isMainSelected = true
                        self.isFavoriteSelected = false
                        self.isTagSelected = false
                        homeViewModel.isFavoriteSelected = false
                        homeViewModel.isTagSelected = false
                    }
                    .padding(.bottom, 3)
                
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isFavoriteSelected ? Color(hex: "EFEFF8") : .clear)
                    .frame(height: 43)
                    .overlay {
                        HStack(spacing: 0) {
                            Image(isFavoriteSelected ? "starfill" : "star")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(isFavoriteSelected ? .primary1 : .gray700)
                                .padding(.trailing, 11)
                            
                            Text("즐겨찾기")
                                .reazyFont(isFavoriteSelected ? .button1 : .text1)
                                .foregroundStyle(isFavoriteSelected ? .primary1 : .gray700)
                            
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                    .onTapGesture {
                        self.isMainSelected = false
                        self.isFavoriteSelected = true
                        self.isTagSelected = false
                        homeViewModel.isFavoriteSelected = true
                        homeViewModel.isTagSelected = false
                    }
                    .padding(.bottom, 3)
                
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isTagSelected ? Color(hex: "EFEFF8") : .clear)
                    .frame(height: 43)
                    .overlay {
                        HStack(spacing: 0) {
                            Image(systemName: isTagSelected ? "tag.fill" : "tag")
                                .font(.system(size: 14))
                                .foregroundStyle(isTagSelected ? .primary1 : .gray700)
                                .padding(.trailing, 11)
                            
                            Text("태그")
                                .reazyFont(isTagSelected ? .button1 : .text1)
                                .foregroundStyle(isTagSelected ? .primary1 : .gray700)
                                
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                    .onTapGesture {
                        self.isMainSelected = false
                        self.isFavoriteSelected = false
                        self.isTagSelected = true
                        homeViewModel.isFavoriteSelected = false
                        homeViewModel.isTagSelected = true
                    }
            }
            .padding(.leading, 10)
            .padding(.trailing, 12)
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray500)
                .padding(.top, 13)
                .padding(.bottom, 20)
                .padding(.leading, 30)
            
            Spacer()
        }
        .padding(.top, 24)
        .background(.primary2)
    }
}

#Preview {
    HomeListView()
}
