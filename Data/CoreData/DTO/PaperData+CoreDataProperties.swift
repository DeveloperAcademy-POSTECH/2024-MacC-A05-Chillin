//
//  PaperData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation
import CoreData

extension PaperData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaperData> {
        return NSFetchRequest<PaperData>(entityName: "PaperData")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var thumbnail: Data
    @NSManaged public var url: Data
    @NSManaged public var focusURL: Data?
    
    // 저장소 디렉터리 기준 상대 경로. url/focusURL 북마크는 기기 전용이라 CloudKit으로
    // 복제되면 다른 기기에서 해석되지 않으므로, 기기 독립적인 이 값을 우선 사용한다
    @NSManaged public var relativePath: String?
    @NSManaged public var focusRelativePath: String?
    @NSManaged public var lastModifiedDate: Date
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isFigureSaved: Bool
    
    @NSManaged public var folderID: UUID?
    
    @NSManaged public var figureData: Set<FigureData>?
    @NSManaged public var collectionData: Set<CollectionData>?
    @NSManaged public var commentData: Set<CommentData>?
    @NSManaged public var paperTags: Set<PaperTag>?
}
