//
//  HomeView.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI

struct HomeView: View {
  
  @State private var selectedButton: HomeButton = .page
  @State private var navigationPath: NavigationPath = NavigationPath()
  
  
  var body: some View {
    NavigationStack(path: $navigationPath) {
      HStack(spacing: 0) {
        ZStack {
          Rectangle()
            .foregroundStyle(.point1)
          
          VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 20)
              .frame(width: 59, height: 59)
              .foregroundStyle(Color(hex: "2F2C9F"))
              .padding(.top, 45)
              .padding(.bottom, 40)
            
            ForEach(HomeButton.allCases, id: \.self) { btn in
              if btn == .setting {
                Spacer()
              }
              HomeViewButton(
                button: $selectedButton,
                buttonOwner: btn) {
                  selectedButton = btn
                }
                .padding(.bottom, btn == .setting ? 15 : 19)
            }
          }
        }
        .frame(width: 80)
        .ignoresSafeArea()
        
        // 화면 추가 시 수정 예정
        switch selectedButton {
        case .page:
          PaperView(navigationPath: $navigationPath)
        case .star:
          BookmarkView()
        case .folder:
          ClippingView()
        case .link:
          LinkView()
        case .setting:
          SettingView()
        }
      }
      .background(Color(hex: "F7F7FB"))
      .navigationDestination(for: Int.self) { index in
        MainPDFView(index: index, navigationPath: $navigationPath)
      }
    }
    .statusBarHidden()
  }
}

struct HomeViewButton: View {
  @Binding var button: HomeButton
  
  let buttonOwner: HomeButton
  let action: () -> Void
  
  var body: some View {
    Button(action: {
      action()
    }) {
      RoundedRectangle(cornerRadius: 14)
        .frame(width: 54, height: 54)
        .foregroundStyle(button == buttonOwner ? .point2 : .clear)
        .overlay(
          Image(systemName: button == buttonOwner ? buttonOwner.selectedIcon : buttonOwner.nonSelectedIcon)
            .resizable()
            .scaledToFit()
            .frame(height: 21)
            .foregroundStyle(button == buttonOwner ? .gray100 : .point3)
        )
    }
  }
}

enum HomeButton: String, CaseIterable {
  case page
  case star
  case folder
  case link
  case setting
  
  var selectedIcon: String {
    switch self {
    case .page:
      "text.page.fill"
    case .star:
      "star.fill"
    case .folder:
      "folder.fill"
    case .link:
      "link"
    case .setting:
      "gearshape.fill"
    }
  }
  
  var nonSelectedIcon: String {
    switch self {
    case .page:
      "text.page"
    case .star:
      "star"
    case .folder:
      "folder"
    case .link:
      "link"
    case .setting:
      "gearshape"
    }
  }
}

#Preview {
  HomeView()
}
