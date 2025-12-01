//
//  HomeViewStatus.swift
//  Reazy
//
//  Created by 문인범 on 7/24/25.
//

import Foundation


enum HomeViewStatus: Hashable {
    case search
    case edit
    case main
    case favorite
    case tag
    case folder(UUID)
    
    public var currentFolderID: UUID? {
        switch self {
        case let .folder(id):
            return id
        default:
            return nil
        }
    }
}
