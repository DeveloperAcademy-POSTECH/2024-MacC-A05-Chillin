//
//  NetworkManager + Server.swift
//  Reazy
//
//  Created by 문인범 on 11/3/24.
//

import Foundation


extension NetworkManager {
    static func fetchPDFLayoutData(pdfURL: URL) async throws -> PDFInfo {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String else {
            throw NetworkManagerError.invalidInfo
        }
        print(urlString)
        
        guard let url = URL(string: "https://" + urlString) else {
            throw NetworkManagerError.invalidURL
        }
        
        guard let pdfData = try? Data(contentsOf: pdfURL) else {
            throw NetworkManagerError.invalidPDF
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        
        var body = Data()
        let fileName = pdfURL.lastPathComponent
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let response = response as? HTTPURLResponse,
           !(200..<300 ~= response.statusCode) {
            print(response.statusCode)
            throw NetworkManagerError.badRequest
        }
        
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(PDFInfo.self, from: data)
        return decodedData
    }
}
