//
//  NotificationCenter + Extension.swift
//  Reazy
//
//  Created by 문인범 on 10/20/24.
//

import Foundation


/**
 Notification Center 이름 등록
 */
extension Notification.Name {
    static let didSelectThumbnail = Notification.Name("didSelectThumbnail")
    static let isCommentTapped = Notification.Name("isCommentTapped")
    static let isPDFInfoMenuHidden = Notification.Name("isPDFInfoMenuHidden")
    static let changeHomePaperInfo = Notification.Name("changeHomePaperInfo")
}
