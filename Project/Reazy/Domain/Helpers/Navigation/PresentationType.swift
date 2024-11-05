//
//  PresentationType.swift
//  Reazy
//
//  Created by 문인범 on 11/5/24.
//

import Foundation


enum Screen: Identifiable, Hashable {
    case mainPDF(url: URL)
    
    var id: Self { self }
}

enum Sheet: Identifiable, Hashable {
    case none
    
    var id: Self { self }
}

enum FullScreenCover: Identifiable, Hashable {

    case none(test: () -> Void)
    
    var id: Self { self }
}


/// Become Hashable and ==
extension FullScreenCover {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .none:
            hasher.combine("none")
        }
    }
    
    static func == (lhs: FullScreenCover, rhs: FullScreenCover) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        }
    }
}
