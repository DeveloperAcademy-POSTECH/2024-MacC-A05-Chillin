//
//  ButtonGroupData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/11/24.
//

import Foundation
import CoreData

extension ButtonGroupData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ButtonGroupData> {
        return NSFetchRequest<ButtonGroupData>(entityName: "ButtonGroupData")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var page: Int32
    @NSManaged public var selectedLine: Data
    @NSManaged public var buttonPosition: Data
    
    @NSManaged public var paperData: PaperData?
}
