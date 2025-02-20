//
//  TagData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 2/9/25.
//

import Foundation
import CoreData

extension TagData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagData> {
        return NSFetchRequest<TagData>(entityName: "TagData")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    
    @NSManaged public var paperTag: Set<PaperTag>?
}
