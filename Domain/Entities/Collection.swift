//
//  Collection.swift
//  Reazy
//
//  Created by 유지수 on 11/27/24.
//

import Foundation

struct Collection {
    let id: String
    var head: String?
    let label: String?
    let figDesc: String?
    let coords: [String]
    let graphicCoord: [String]?
    
    public func toEntity(pageHeight: CGFloat) -> FigureAnnotation {
        let id = self.id
        let head = self.head
        var page = -1
        var x0 = -1.0
        var x1 = -1.0
        var y0 = -1.0
        var y1 = -1.0
        
        
        for coord in self.coords {
            let array = coord.split(separator: ",")
            
            page = Int(array[0])!
            let tempX0 = Double(array[1])!
            let tempX1 = Double(array[1])! + Double(array[3])!
            let tempY0 = Double(array[2])!
            let tempY1 = Double(array[2])! + Double(array[4])!
            
            if x0 == -1 {
                x0 = tempX0
                x1 = tempX1
                y0 = tempY0
                y1 = tempY1
                
                continue
            }
            
            x0 = min(x0, tempX0)
            x1 = max(x1, tempX1)
            y0 = min(y0, tempY0)
            y1 = max(y1, tempY1)
        }
        
        return .init(
            uuid: UUID(),
            id: id,
            page: page,
            head: head ?? id,
            position: .init(
                x: x0,
                y: pageHeight - y1,
                width: x1 - x0,
                height: y1 - y0),
            label: label,
            figDesc: figDesc,
            coords: coords,
            graphicCoord: graphicCoord
        )
    }
}
