//
//  CollectionData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/27/24.
//

import Foundation
import CoreData

extension CollectionData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CollectionData> {
        return NSFetchRequest<CollectionData>(entityName: "CollectionData")
    }
    
    @NSManaged public var id: String
    @NSManaged public var head: String?
    @NSManaged public var coords: [String]
    
    @NSManaged public var paperData: PaperData?
}
