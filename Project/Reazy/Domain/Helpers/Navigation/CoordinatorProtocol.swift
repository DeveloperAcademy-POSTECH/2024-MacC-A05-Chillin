//
//  CoordinatorProtocol.swift
//  Reazy
//
//  Created by 문인범 on 11/5/24.
//

import SwiftUI


protocol CoordinatorProtocol: ObservableObject {
    var path: NavigationPath { get set }
    var sheet: Sheet? { get set }
    var fullScreenCover: FullScreenCover? { get set }
    
    func push(_ screen: Screen)
    func presentSheet(_ sheet: Sheet)
    func presentFullScreenCover(_ fullScreenCover: FullScreenCover)
    
    func pop()
    func popToRoot()
    
    func dismissSheet()
    func dismissFullScreenCover()
    
}
