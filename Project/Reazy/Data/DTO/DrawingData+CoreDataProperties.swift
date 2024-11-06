//
//  DrawingData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation
import CoreData

extension DrawingData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrawingData> {
        return NSFetchRequest<DrawingData>(entityName: "DrawingData")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var pageIndex: Int32
    @NSManaged public var path: Data?
    @NSManaged public var color: Data?
    
    @NSManaged public var paperData: PaperData?
}
