//
//  TranslationManager.swift
//  Reazy
//
//  Created by 문인범 on 11/1/25.
//

import SwiftUI
import Translation
import FirebaseAnalytics
import NaturalLanguage


@Observable
public final class TranslationManager {
    // 번역 결과 텍스트
    public var targetText = ""
    
    public var maxBubbleWidth: CGFloat = 400 // bubble 최대 너비
    public var minBubbleWidth: CGFloat = 250 // bubble 최대 너비
    public var maxBubbleHeight: CGFloat = 280 // bubble 최대 높이
    
    public var textHeight: CGFloat = 30 // 텍스트 높이 저장
    
    public var isPopoverVisible: Bool = false
    public var updatedBubblePosition: CGPoint = .zero // 조정된 bubble view 위치
    
    // 번역 완료 되었는지 확인해 뷰 새로 그리기 위한 flag
    public var isTranslationComplete: Bool = false {
        didSet {
            if isTranslationComplete { isPopoverVisible = true }
        }
    }
    
    public var isCopySuccess: Bool = false // 복사 성공 여부
    
    // BubbleView의 상태와 위치
    var translateViewPosition: CGRect = .zero
    var selectedText: String = "" {
        didSet {
            updateTranslationView(bubblePosition: translateViewPosition)
        }
    }
    
    
    public func updateTranslationView(bubblePosition: CGRect) {
        // 선택된 텍스트가 있을 경우 TranslationView를 보이게 하고 위치를 업데이트
        if !selectedText.isEmpty {
            self.translateViewPosition = bubblePosition
        }
    }
    
    // TranslateView 위치 조정하는 함수
    public func bubblePositionForScreen(in screenSize: CGSize) {
        DispatchQueue.main.async {
            self.updatedBubblePosition = CGPoint(x: self.translateViewPosition.midX, y: self.translateViewPosition.minY)
        }
    }
    
    @available(iOS 18.0, *)
    public func translateAction(session: TranslationSession) async {
        do {
            let cleanedText = removeHyphen(in: self.selectedText)
            let response = try await session.translate(cleanedText)
            
            self.targetText = response.targetText
            if !self.targetText.isEmpty {
                self.isTranslationComplete = true
                self.isPopoverVisible = true
                
                // word_count 계산 및 기능 사용 로그
                let wordCount = countWords(in: cleanedText)
                
                // GA - 번역에 사용된 글자수 로그
                AnalyticsManager.sendEvent(eventType: .translationTriggered, parameters: "\(wordCount)")
            }
        } catch {
            log(error.localizedDescription)
        }
    }
    
    // 줄바꿈 전에 있는 '-'를 제거하는 함수
    private func removeHyphen(in text: String) -> String {
        var result = ""
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        for line in lines {
            if line.hasSuffix("-") {
                result += line
            } else {
                result += line
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // GA - 번역에 사용된 글자 수
    private func countWords(in text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.english) // 혹은 .korean
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            count += 1
            return true
        }
        return count
    }
}
