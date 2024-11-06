//
//  PresentationType.swift
//  Reazy
//
//  Created by 문인범 on 11/5/24.
//

import Foundation

/**
 네비게이션에 사용되는 열거형 입니다. 추가해야되는 뷰가 있을 경우 해당 열거형을 수정하면 됩니다.
 Screen: Navigation에 사용되는 열거형입니다.
 Sheet: 바텀 시트에 사용되는 열거형입니다.
 FullScreenCover: 화면을 덮는 시트에 사용되는 열거형 입니다.
 */



enum Screen: Identifiable, Hashable {
    case home
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
