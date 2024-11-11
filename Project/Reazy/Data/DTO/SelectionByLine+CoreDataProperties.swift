//
//  SelectionByLine+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/11/24.
//

import Foundation
import CoreData

extension SelectionByLine {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SelectionByLine> {
        return NSFetchRequest<SelectionByLine>(entityName: "SelectionByLine")
    }
    
    @NSManaged public var page: Int32
    @NSManaged public var bounds: Data
    
    @NSManaged public var commentData: CommentData?
}
