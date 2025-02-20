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
    
    @NSManaged public var paperData: PaperData
    @NSManaged public var tagData: TagData
}
