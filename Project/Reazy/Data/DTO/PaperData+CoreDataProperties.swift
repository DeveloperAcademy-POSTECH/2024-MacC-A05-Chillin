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
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var dateTime: String?
    @NSManaged public var author: String?
    @NSManaged public var year: String?
    @NSManaged public var pages: Int32
    @NSManaged public var publisher: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var url: Data?
    @NSManaged public var lastModifiedDate: Date?
    @NSManaged public var isFavorite: Bool
    
    @NSManaged public var drawingData: Set<DrawingData>?
}
