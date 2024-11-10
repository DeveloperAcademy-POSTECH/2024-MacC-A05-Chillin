//
//  FigureData+CoreDataProperties.swift
//  Reazy
//
//  Created by 유지수 on 11/10/24.
//

import Foundation
import CoreData

extension FigureData {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FigureData> {
        return NSFetchRequest<FigureData>(entityName: "FigureData")
    }
    
    @NSManaged public var id: String
    @NSManaged public var head: String?
    @NSManaged public var label: String?
    @NSManaged public var figDesc: String?
    @NSManaged public var coords: [String]
    @NSManaged public var graphicCoord: [String]?
    
    @NSManaged public var paperData: PaperData?
}
