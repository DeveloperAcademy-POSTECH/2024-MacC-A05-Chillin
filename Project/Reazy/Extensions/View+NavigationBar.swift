//
//  View+NavigationBar.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//

import SwiftUI

// MARK: - 커스텀 Navigation Bar
struct CustomNavigationBarModifier<C, L, R>: ViewModifier where C : View, L : View, R : View {
  let centerView: (() -> C)?
  let leftView: (() -> L)?
  let rightView: (() -> R)?
  
  init(centerView: (() -> C)? = nil, leftView: (() -> L)? = nil, rightView: (() -> R)? = nil) {
    self.centerView = centerView
    self.leftView = leftView
    self.rightView = rightView
  }
  
  func body(content: Content) -> some View {
    VStack(spacing: 0) {
      ZStack {
        HStack {
          self.leftView?()
          Spacer()
          self.rightView?()
        }
        .frame(height: 51)
        .frame(width: .infinity)
        .padding(.horizontal, 20)
        
        HStack {
          Spacer()
          self.centerView?()
          Spacer()
        }
      }
      .padding(.top, 10)
      .background(Color(hex: "EAECF9"))
      
      content
    }
    .navigationBarHidden(true)
  }
}

struct WillDisappearModifier: ViewModifier {
  let callback: () -> Void
  
  func body(content: Content) -> some View {
    content
      .onDisappear {
        callback()
      }
  }
}


extension View {
  func onWillDisappear(_ perform: @escaping () -> Void) -> some View {
    self.modifier(WillDisappearModifier(callback: perform))
  }
  
  func customNavigationBar<C, L, R> (
    centerView: @escaping (() -> C),
    leftView: @escaping (() -> L),
    rightView: @escaping (() -> R)
  ) -> some View where C: View, L: View, R: View {
    modifier(
      CustomNavigationBarModifier(centerView: centerView, leftView: leftView, rightView: rightView)
    )
  }
  
  func customNavigationBar<V> (
    centerView: @escaping (() -> V)
  ) -> some View where V: View {
    modifier(
      CustomNavigationBarModifier(
        centerView: centerView,
        leftView: {
          EmptyView()
        }, rightView: {
          EmptyView()
        }
      )
    )
  }
}
