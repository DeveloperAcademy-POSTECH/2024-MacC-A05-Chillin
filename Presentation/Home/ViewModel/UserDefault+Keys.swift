//
//  UserDefault+Keys.swift
//  Reazy
//
//  Created by 유지수 on 11/24/24.
//

import Foundation

struct UserDefaultsKeys {
    static let recentSearches = "RecentSearches"
    static let lastSearchTags = "LastSearchTags"
    static let focusGuideViewDoNotShowAgain = "FocusGuideViewDoNotShowAgain"
    static let isICloudEnabled = "IsICloudEnabled"
}

extension UserDefaults {
    // 최근 검색 기록
    var recentSearches: [String] {
        get {
            return UserDefaults.standard.array(forKey: UserDefaultsKeys.recentSearches) as? [String] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.recentSearches)
        }
    }
    
    // 태그 관리 내 최근 검색 기록
    var lastSearchTags: [String: String] {
        get {
            UserDefaults.standard.dictionary(forKey: UserDefaultsKeys.lastSearchTags) as? [String: String] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.lastSearchTags)
        }
    }
    
    public var focusGuideViewDoNotShowAgain: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.focusGuideViewDoNotShowAgain)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.focusGuideViewDoNotShowAgain)
        }
    }

    // iCloud Drive에 PDF 파일 저장 여부 (기본값: false → 기존 동작 유지)
    public var isICloudEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKeys.isICloudEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.isICloudEnabled)
        }
    }
}
