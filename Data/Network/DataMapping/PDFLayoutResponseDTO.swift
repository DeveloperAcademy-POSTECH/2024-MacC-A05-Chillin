//
//  PDFInfo.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation


/**
 Grobid 모델에서 PDF 분석 결과를 받아오는 구조체
 */
struct PDFLayoutResponseDTO: Codable {
    let fig: [Figure]
    let table: [Figure]?
    
    public func toEntities(pageHeight: CGFloat) -> [FigureAnnotation] {
        var result = [FigureAnnotation]()
        
        for coords in self.fig {
            let head = coords.head
            var page = -1
            var x0 = -1.0
            var x1 = -1.0
            var y0 = -1.0
            var y1 = -1.0
            
            for coord in coords.coords {
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
            
            result.append(.init(
                page: page,
                head: head ?? "nil",
                position: .init(
                    x: x0,
                    y: pageHeight - y1,
                    width: x1 - x0,
                    height: y1 - y0)))
        }
        
        return result
    }
    
    public func toCoreData() -> [Figure] {
        self.fig.map {
            .init(
                id: $0.id,
                head: $0.head,
                label: $0.label,
                figDesc: $0.figDesc,
                coords: $0.coords,
                graphicCoord: $0.graphicCoord)
        }
    }
}

struct Figure: Codable {
    let id: String
    let head: String?
    let label: String?
    let figDesc: String?
    let coords: [String]
    let graphicCoord: [String]?
    
    public func toEntity(pageHeight: CGFloat) -> FigureAnnotation {
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
            page: page,
            head: head ?? "nil",
            position: .init(
                x: x0,
                y: pageHeight - y1,
                width: x1 - x0,
                height: y1 - y0))
    }
}