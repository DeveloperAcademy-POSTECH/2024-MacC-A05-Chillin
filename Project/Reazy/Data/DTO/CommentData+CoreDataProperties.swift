//
//  CommentData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/7/24.
//

import Foundation
import CoreData

extension CommentData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CommentData> {
        return NSFetchRequest<CommentData>(entityName: "CommentData")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var buttonID: String
    @NSManaged public var pageIndex: Int32
    @NSManaged public var startIndex: Int32
    @NSManaged public var length: Int32
    @NSManaged public var text: String?
    @NSManaged public var selectedLine: Data?
    
    @NSManaged public var paperData: PaperData?
}
