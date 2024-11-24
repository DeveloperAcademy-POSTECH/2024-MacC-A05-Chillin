//
//  UserDefault+Keys.swift
//  Reazy
//
//  Created by 유지수 on 11/24/24.
//

import Foundation

struct UserDefaultsKeys {
    static let recentSearches = "RecentSearches"
}

extension UserDefaults {
    var recentSearches: [String] {
        get {
            return UserDefaults.standard.array(forKey: UserDefaultsKeys.recentSearches) as? [String] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.recentSearches)
        }
    }
}
