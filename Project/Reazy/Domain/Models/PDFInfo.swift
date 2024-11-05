//
//  PDFInfo.swift
//  Reazy
//
//  Created by 문인범 on 11/5/24.
//

import Foundation


struct PDFInfo: Codable {
    let title: String?
    let names: [String]?
    let date: Publication?
    
    struct Publication: Codable {
        let date: String
        let engDate: String
        
        enum CodingKeys: String, CodingKey {
            case date = "@when"
            case engDate = "#text"
        }
    }
}


