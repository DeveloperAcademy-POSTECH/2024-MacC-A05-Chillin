//
//  NetworkManager + Grobid.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation


extension NetworkManager {
    /// sample 데이터 불러오기
    static func getSamplePDFData() throws -> PDFInfo {
        guard let samplePDFUrl = Bundle.main.url(forResource: "engPD5", withExtension: "pdf") else {
            throw NetworkManagerError.invalidURL
        }
        
        do {
            let data = try Data(contentsOf: samplePDFUrl)
            
            let decodedResult = try JSONDecoder().decode(PDFInfo.self, from: data)
            
            return decodedResult
        } catch {
            throw error
        }
    }
}
