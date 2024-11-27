//
//  NetworkUnitTest.swift
//  NetworkUnitTest
//
//  Created by 문인범 on 11/4/24.
//

import Testing
import Foundation
@testable import Reazy

struct NetworkUnitTest {

    @Test func testNetwork() async throws {
        let tempPath = NSTemporaryDirectory()
        print(tempPath)
        print(try! FileManager.default.contentsOfDirectory(atPath: tempPath))
    }
    
    @Test func testNetwork2() async throws {
        let pdfURL = Bundle.main.url(forResource: "engPD5", withExtension: "pdf")!
        let data: PDFLayoutResponseDTO = try await NetworkManager.fetchPDFExtraction(process: .processFulltextDocument, pdfURL: pdfURL)
        
//        #expect()
    }

}
