//
//  NetworkManager + Server.swift
//  Reazy
//
//  Created by 문인범 on 11/3/24.
//

import Foundation

/**
 pdf 분석 관련 메소드
 */
extension NetworkManager {
    // 서버에 pdf 데이터 전송
    static func fetchPDFLayoutData(pdfURL: URL) async throws -> PDFInfo {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String else {
            throw NetworkManagerError.invalidInfo
        }
        
        guard let url = URL(string: "https://" + urlString) else {
            throw NetworkManagerError.invalidURL
        }
        
        guard let pdfData = try? Data(contentsOf: pdfURL) else {
            throw NetworkManagerError.invalidPDF
        }
        
        // multipart data 구분자 설정
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // HTTPRequest 생성
        var request = URLRequest(url: url)
        
        // Header 설정
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Body 설정
        // multipart/form-data 사용
        var body = Data()
        let fileName = pdfURL.lastPathComponent
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)
        
        if let response = response as? HTTPURLResponse,
           !(200..<300 ~= response.statusCode) {
            print("request error!, statusCode\(response.statusCode)")
            throw NetworkManagerError.badRequest
        }
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(PDFInfo.self, from: data)
        
        return decodedData
    }
}
