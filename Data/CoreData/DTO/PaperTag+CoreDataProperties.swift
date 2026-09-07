//
//  PaperTag+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 2/9/25.
//

import Foundation
import CoreData

extension PaperTag {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaperTag> {
        return NSFetchRequest<PaperTag>(entityName: "PaperTag")
    }
    
    @NSManaged public var id: UUID
    
    // CloudKit은 관계 레코드를 각각 따로 전송하므로 동기화가 끝나기 전까지 일시적으로 nil일 수 있다.
    // (모델 4.1에서 optional로 전환한 것과 짝을 맞춘 선언 — non-optional로 두면 그 순간 크래시한다)
    @NSManaged public var paperData: PaperData?
    @NSManaged public var tagData: TagData?
}
