//
//  PDFInfo.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation



struct PDFInfo: Codable {
    let div: [Division]
    let fig: [Figure]
    let table: [Figure]?
    
    
    struct Division: Codable {
        let header: String
        let coords: [String]
        
        enum CodingKeys: String, CodingKey {
            case header
            case coords = "@coords"
        }
    }
    
    struct Figure: Codable {
        let id: String
        let head: String
        let label: String
        let figDesc: String
        let coords: [String]
        let graphicCoord: [String]?
    }
}


