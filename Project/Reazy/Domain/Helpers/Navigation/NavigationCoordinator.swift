//
//  NavigationCoordinator.swift
//  Reazy
//
//  Created by 문인범 on 11/5/24.
//

import SwiftUI


final class NavigationCoordinator: CoordinatorProtocol {
    @Published public var path: NavigationPath = .init()
    @Published var sheet: Sheet?
    @Published var fullScreenCover: FullScreenCover?
    
    func push(_ screen: Screen) {
        path.append(screen)
    }
    
    func presentSheet(_ sheet: Sheet) {
        self.sheet = sheet
    }
    
    func presentFullScreenCover(_ fullScreenCover: FullScreenCover) {
        self.fullScreenCover = fullScreenCover
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    func dismissSheet() {
        self.sheet = nil
    }
    
    func dismissFullScreenCover() {
        self.fullScreenCover = nil
    }
    
    @ViewBuilder
    func build(_ screen: Screen) -> some View {
        switch screen {
        case .mainPDF(let url):
            MainPDFView(navigationPath: .constant(.init()))
        }
    }
    
}












