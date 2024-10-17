//
//  HomeView.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI

struct HomeView: View {
  
  @State private var isSelected: [Bool] = [true, false, false, false, false]
  @State private var nonselectedIcons: [String] = ["text.page", "star", "folder", "link", "gearshape"]
  @State private var selectedIcons: [String] = ["text.page.fill", "star.fill", "folder.fill", "link", "gearshape.fill"]
  
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
            
            ForEach(0..<isSelected.count, id: \.self) { index in
              if index < 4 {
                Button(action: {
                  isSelected.toggleSelection(at: index)
                }) {
                  RoundedRectangle(cornerRadius: 14)
                    .frame(width: 54, height: 54)
                    .foregroundStyle(isSelected[index] ? .point2 : .clear)
                    .overlay(
                      Image(systemName: isSelected[index] ? selectedIcons[index] : nonselectedIcons[index])
                        .resizable()
                        .scaledToFit()
                        .frame(height: 21)
                        .foregroundStyle(isSelected[index] ? .gray100 : .point3)
                    )
                }
                .padding(.bottom, 16)
              } else {
                VStack(spacing: 0) {
                  Spacer()
                  Button(action: {
                    isSelected.toggleSelection(at: index)
                  }) {
                    RoundedRectangle(cornerRadius: 14)
                      .frame(width: 54, height: 54)
                      .foregroundStyle(isSelected[index] ? .point2 : .clear)
                      .overlay(
                        Image(systemName: isSelected[index] ? selectedIcons[index] : nonselectedIcons[index])
                          .resizable()
                          .scaledToFit()
                          .frame(width: 15)
                          .foregroundStyle(isSelected[index] ? .gray100 : .point3)
                      )
                  }
                  .padding(.bottom, 16)
                }
              }
            }
            
            Spacer()
          }
        }
        .frame(width: 80)
        .ignoresSafeArea()
        
        if isSelected[0] {
          PaperView(navigationPath: $navigationPath)
        } else {
          TestView()
        }
      }
      .background(Color(hex: "F7F7FB"))
      .navigationDestination(for: Int.self) { index in
        PDFView(index: index, navigationPath: $navigationPath)
      }
      .onTapGesture {
        hideKeyboard()
      }
    }
    .statusBarHidden()
  }
}

#Preview {
  HomeView()
}

#if canImport(UIKit)
extension View {
  func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
#endif
