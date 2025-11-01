//
//  AnalyticsManager.swift
//  Reazy
//
//  Created by 문인범 on 11/1/25.
//

import Foundation
import FirebaseAnalytics


final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}
    
    private var splitEnterTime: Date?
    private var floatingViewTrackers: [FloatingViewTracker] = []
    
    
    static func sendEvent(eventType: AnalyticsEvent, parameters: String...) {
        let params: [String: String] = {
            var idx = 0
            
            var result = [String: String]()
            
            eventType.parameters.forEach {
                result.updateValue($0, forKey: parameters[idx])
                idx += 1
            }
            return result
        }()
        
        Analytics.logEvent(
            eventType.eventName,
            parameters: params
        )
    }
}


extension AnalyticsManager {
    public func startSplitEnterTime() {
        self.splitEnterTime = .now
    }
    
    public func logSplitEnterTime() -> TimeInterval {
        if let time = self.splitEnterTime {
            return Date.now.timeIntervalSince(time)
        }
        return -1
    }
    
    public func startFloatingViewEnterTime(id: UUID) {
        floatingViewTrackers.append(.init(id: id, startDate: .now))
    }
    
    public func logFloatingViewEnterTime(id: UUID) -> TimeInterval {
        if let idx = floatingViewTrackers.firstIndex(where: { $0.id == id }) {
            let result = Date.now.timeIntervalSince(floatingViewTrackers[idx].startDate)
            floatingViewTrackers.remove(at: idx)
            return result
        }
        return -1
    }
    
    
    struct FloatingViewTracker {
        let id: UUID
        let startDate: Date
    }
}




enum AnalyticsEvent {
    case figureButtonClick
    case extractButtonClick
    case extractSuccess
    case extractFail
    
    case floatingWindowOpen
    case splitViewOpen
    case floatingWindowClose
    case splitViewClose
    case floatingWindowDuration
    case splitViewDuration
    case figureBlockClick
    case splitViewFigureClick
    case floatingWindowPageMove
    
    public var eventName: String {
        switch self {
        case .figureButtonClick:
            "figure_button_click"
        case .extractButtonClick:
            "extract_button_click"
        case .extractSuccess:
            "extract_success"
        case .extractFail:
            "extract_fail"
        case .floatingWindowOpen:
            "floating_window_open"
        case .splitViewOpen:
            "split_view_open"
        case .floatingWindowClose:
            "floating_window_close"
        case .splitViewClose:
            "split_view_close"
        case .floatingWindowDuration:
            "floating_window_duration"
        case .splitViewDuration:
            "split_view_duration"
        case .figureBlockClick:
            "figure_block_click"
        case .splitViewFigureClick:
            "split_view_figure_click"
        case .floatingWindowPageMove:
            "floating_window_page_move"
        }
    }
    
    public var parameters: [String] {
        switch self {
        case .figureButtonClick:
            ["article_id"]
        case .extractButtonClick:
            ["article_id", "extract_time"]
        case .extractSuccess:
            ["article_id", "figure_count"]
        case .extractFail:
            ["article_id", "error_code"]
        case .floatingWindowOpen:
            ["article_id", "figure_id"]
        case .splitViewOpen:
            ["article_id", "button_location"]
        case .floatingWindowClose:
            ["article_id", "figure_id"]
        case .splitViewClose:
            ["article_id"]
        case .floatingWindowDuration:
            ["article_id", "figure_id", "duration_sec"]
        case .splitViewDuration:
            ["article_id", "duration_sec"]
        case .figureBlockClick:
            ["article_id", "figure_id"]
        case .splitViewFigureClick:
            ["article_id", "figure_id"]
        case .floatingWindowPageMove:
            ["article_id", "figure_id", "current_page"]
        }
    }
}
