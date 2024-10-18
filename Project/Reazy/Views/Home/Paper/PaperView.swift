//
//  PaperView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI

enum options {
  case main
  case search
  case edit
}

// MARK: - 홈 뷰 : 논문 리스트 뷰
struct PaperView: View {
  
  @State var selectedMenu: options = .main
  
  @State private var searchText: String = ""
  
  @State private var selectedPaper: Int? = nil
  
  @State private var isStarSelected: Bool = false
  @State private var isFolderSelected: Bool = false
  
  @State private var isEditing: Bool = false
  @State private var selectedItems: Set<Int> = []
  
  @Binding var navigationPath: NavigationPath
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        Text("논문")
          .reazyFont(.h1)
          .padding(.leading, 26)
        Spacer()
        
        switch selectedMenu {
        case .main:
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              selectedMenu = .search
            }
          }) {
            Image(systemName: "magnifyingglass")
              .resizable()
              .scaledToFit()
              .frame(height: 19)
              .foregroundStyle(.primary1)
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
              .foregroundStyle(.primary1)
          }
          .padding(.trailing, 28)
          
          Button(action: {
            
          }) {
            Text("업로드")
              .reazyFont(.button1)
              .foregroundStyle(.primary1)
          }
          .padding(.trailing, 28)
          
      case .search:
          SearchBar(text: $searchText)
            .frame(width: 400)
          
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              selectedMenu = .main
            }
          }, label: {
            Text("취소")
              .reazyFont(.button1)
              .foregroundStyle(.primary1)
          })
          .padding(.trailing, 28)
          
      case .edit:
          Button(action: {
            
          }, label: {
            Image(systemName: "trash")
              .resizable()
              .scaledToFit()
              .frame(height: 19)
              .foregroundStyle(.primary1)
          })
          .padding(.trailing, 28)
          
          Button(action: {
            
          }, label: {
            Image(systemName: "folder.badge.plus")
              .resizable()
              .scaledToFit()
              .frame(height: 19)
              .foregroundStyle(.primary1)
          })
          .padding(.trailing, 28)
          
          Button(action: {
            
          }, label: {
            Image(systemName: "square.and.arrow.up")
              .resizable()
              .scaledToFit()
              .frame(height: 19)
              .foregroundStyle(.primary1)
          })
          .padding(.trailing, 28)
          
          Button(action: {
            selectedMenu = .main
            isEditing = false
            selectedItems.removeAll()
          }, label: {
            Text("취소")
              .reazyFont(.button1)
              .foregroundStyle(.primary1)
          })
          .padding(.trailing, 28)
        }
      }
      .padding(.vertical, 20)
        
      Divider()
      
      PaperListView(
        isEditing: isEditing,
        selectedItems: $selectedItems,
        navigationPath: $navigationPath
      )
    }
    .background(Color(hex: "F7F7FB"))
    .ignoresSafeArea()
  }
}

#Preview {
  PaperView(navigationPath: .constant(NavigationPath()))
}
