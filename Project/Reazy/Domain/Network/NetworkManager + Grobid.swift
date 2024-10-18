//
//  NetworkManager + Grobid.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation

/**
 Grobid 모델과 통신 관련 메소드
 */
extension NetworkManager {
    /// sample 데이터 불러오기
    static func getSamplePDFData() throws -> PDFInfo {
        guard let samplePDFUrl = Bundle.main.url(forResource: "engPD5Output", withExtension: "json") else {
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
    
    /// sample 데이터 좌표 필터링 메소드
    static func filterSampleData(input: PDFInfo, pageWidth: CGFloat, pageHeight: CGFloat) -> [FocusAnnotation] {
        var result = [FocusAnnotation]()
        
        
        for coords in input.div {
            let header = coords.header
            var currentPage = -1
            var x0 = -1.0
            var x1 = -1.0
            var y0 = -1.0
            var y1 = -1.0
            
            var isNext = false
            
            for coord in coords.coords {
                let array = coord.split(separator: ",")
                
                let page = Int(array[0])!
                let tempX0 = Double(array[1])!
                let tempX1 = Double(array[1])! + Double(array[3])!
                let tempY0 = Double(array[2])!
                let tempY1 = Double(array[2])! + Double(array[4])!
                
                
                if x0 == -1 {
                    currentPage = page
                    x0 = tempX0
                    x1 = tempX1
                    y0 = tempY0
                    y1 = tempY1
                    
                    continue
                }
                
                if tempX0 > pageWidth / 2.0 && !isNext {
                    currentPage = page
                    let focus = FocusAnnotation(page: currentPage, header: header, position: .init(
                        x: x0,
                        y: pageHeight - y1,
                        width: x1 - x0,
                        height: y1 - y0))
                    
                    result.append(focus)
                    
                    x0 = tempX0
                    x1 = tempX1
                    y0 = tempY0
                    y1 = tempY1
                    
                    isNext = true
                    continue
                    
                } else if currentPage != page {
                    let focus = FocusAnnotation(page: currentPage, header: header, position: .init(
                        x: x0,
                        y: pageHeight - y1,
                        width: x1 - x0,
                        height: y1 - y0))
                    
                    result.append(focus)
                    
                    currentPage = page
                    
                    x0 = tempX0
                    x1 = tempX1
                    y0 = tempY0
                    y1 = tempY1
                    
                    isNext = false
                    continue
                }
                
                x0 = min(x0, tempX0)
                x1 = max(x1, tempX1)
                y0 = min(y0, tempY0)
                y1 = max(y1, tempY1)
            }
            
            let focus = FocusAnnotation(page: currentPage, header: header, position: .init(
                x: x0,
                y: pageHeight - y1,
                width: x1 - x0,
                height: y1 - y0))
            
            result.append(focus)
        }
        return result
    }
}
