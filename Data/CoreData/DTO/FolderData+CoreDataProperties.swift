//
//  FolderData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/19/24.
//

import Foundation
import UIKit
import CoreData

extension FolderData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FolderData> {
        return NSFetchRequest<FolderData>(entityName: "FolderData")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var color: String
    @NSManaged public var parentFolderID: UUID?
}
