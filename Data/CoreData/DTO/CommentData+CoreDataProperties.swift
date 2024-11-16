//
//  CommentData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/11/24.
//

import Foundation
import CoreData

extension CommentData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CommentData> {
        return NSFetchRequest<CommentData>(entityName: "CommentData")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var buttonID: UUID
    @NSManaged public var text: String
    @NSManaged public var selectedText: String
    @NSManaged public var selectionByLine: Set<SelectionByLine>
    @NSManaged public var pages: [Int]
    @NSManaged public var bounds: Data
    
    @NSManaged public var paperData: PaperData?
}
