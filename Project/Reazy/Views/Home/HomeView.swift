//
//  HomeView.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI

enum options {
  case main
  case search
  case edit
}

struct HomeView: View {
  
  @State private var navigationPath: NavigationPath = NavigationPath()
  
  @State var selectedMenu: options = .main
  
  // 검색 모드 search text
  @State private var searchText: String = ""
  
  @State private var isStarSelected: Bool = false
  @State private var isFolderSelected: Bool = false
  
  @State private var isEditing: Bool = false
  @State private var isSearching: Bool = false
  @State private var selectedItems: Set<Int> = []
  
  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        ZStack {
          Rectangle()
            .foregroundStyle(.point1)
          
          HStack(spacing: 0) {
            Image("icon")
              .resizable()
              .scaledToFit()
              .frame(width: 54, height: 50)
              .padding(.vertical, 31)
              .padding(.leading, 28)
            
            Spacer()
            
            switch selectedMenu {
            case .main:
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  selectedMenu = .search
                }
                isSearching.toggle()
              }) {
                Image(systemName: "magnifyingglass")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 19)
                  .foregroundStyle(.gray100)
              }
              .padding(.trailing, 28)
              
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  selectedMenu = .edit
                }
                isEditing.toggle()
                selectedItems.removeAll()
              }) {
                Image(systemName: "checkmark.circle")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 19)
                  .foregroundStyle(.gray100)
              }
              .padding(.trailing, 28)
              
              Button(action: {
                
              }) {
                Text("업로드")
                  .reazyFont(.button1)
                  .foregroundStyle(.gray100)
              }
              .padding(.trailing, 28)
              
            case .search:
              SearchBar(text: $searchText)
                .frame(width: 400)
              
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  selectedMenu = .main
                }
                isSearching.toggle()
              }, label: {
                Text("취소")
                  .reazyFont(.button1)
                  .foregroundStyle(.gray100)
              })
              .padding(.trailing, 28)
              
            case .edit:
              Button(action: {
                // MARK: - 북마크 로직 확인 필요
                isStarSelected.toggle()
              }, label : {
                Image(systemName: isStarSelected ? "star.fill" : "star")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 19)
                  .foregroundStyle(.gray100)
              })
              .padding(.trailing, 28)
              
              Button(action: {
                
              }, label: {
                Image(systemName: "trash")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 19)
                  .foregroundStyle(.gray100)
              })
              .padding(.trailing, 28)
              
              Button(action: {
                
              }, label: {
                Image(systemName: "folder.badge.plus")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 19)
                  .foregroundStyle(.gray100)
              })
              .padding(.trailing, 28)
              
              Button(action: {
                
              }, label: {
                Image(systemName: "square.and.arrow.up")
                  .resizable()
                  .scaledToFit()
                  .frame(height: 19)
                  .foregroundStyle(.gray100)
              })
              .padding(.trailing, 28)
              
              Button(action: {
                selectedMenu = .main
                isEditing = false
                selectedItems.removeAll()
                isStarSelected = false
              }, label: {
                Text("취소")
                  .reazyFont(.button1)
                  .foregroundStyle(.gray100)
              })
              .padding(.trailing, 28)
            }
          }
        }
        .frame(height: 80)
        
        PaperListView(
          navigationPath: $navigationPath,
          isEditing: $isEditing,
          isSearching: $isSearching
        )
      }
      .background(Color(hex: "F7F7FB"))
      .navigationDestination(for: Int.self) { index in
        MainPDFView(index: index, navigationPath: $navigationPath)
      }
    }
    .statusBarHidden()
  }
}

#Preview {
  HomeView()
}
