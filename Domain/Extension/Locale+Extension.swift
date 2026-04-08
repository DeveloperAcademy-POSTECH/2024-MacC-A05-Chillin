//
//  Locale+Extension.swift
//  Reazy
//
//  Created by 문인범 on 11/10/25.
//

import Foundation



extension Locale {
    public enum CurrentLangCode {
        case ko     /// Korean
        case en     /// English
        case ja     /// Japanese
        case etc
    }
    
    static func currentLang() -> CurrentLangCode {
        guard let languageCode = Locale.current.language.languageCode?.identifier else {
            return .etc
        }
        
        switch languageCode {
        case "ko": return .ko
        case "en": return .en
        case "ja": return .ja
        default: return .etc
        }
    }
    
    static func currentLangGuideURL() -> URL {
        switch currentLang() {
        case .ko: Bundle.main.url(forResource: "Reazy 사용 가이드", withExtension: "pdf")!
        case .en, .etc: Bundle.main.url(forResource: "Reazy User Guide", withExtension: "pdf")!
        case .ja: Bundle.main.url(forResource: "Reazy ユーザーガイド", withExtension: "pdf")!
        }
    }
}
