//
//  FocusFigureRepositoryImpl.swift
//  Reazy
//
//  Created by 문인범 on 11/15/24.
//

import Foundation
import Combine


class FocusFigureRepositoryImpl: FocusFigureRepository {
    private let baseProcess: NetworkManager.ServiceName
    
    
    init(baseProcess: NetworkManager.ServiceName) {
        self.baseProcess = baseProcess
    }
    
    
    func fetchFocusAndFigures(
        process: NetworkManager.ServiceName,
        url: URL,
        completion: @escaping (Result<PDFLayoutResponseDTO, NetworkManagerError>) -> Void
    ) async {
        
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_URL") as? String else {
            completion(.failure(.invalidInfo))
            return
        }
        
        guard let requestUrl = URL(string: "https://" + urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        guard let pdfData = try? Data(contentsOf: url) else {
            completion(.failure(.invalidPDF))
            return
        }
        
        // multipart data 구분자 설정
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // HTTPRequest 생성
        var request = URLRequest(url: requestUrl)
        
        // Header 설정
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(process.rawValue, forHTTPHeaderField: "serviceName")
        
        // Body 설정
        // multipart/form-data 사용
        var body = Data()
        let fileName = url.lastPathComponent
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: body)
            
            if let response = response as? HTTPURLResponse {
                // 500 error, PDF OCR 적용이 안되어있음
                if (500 ..< 600 ~= response.statusCode) {
                    let decoder = JSONDecoder()
                    let errorResult = try! decoder.decode(ErrorDescription.self, from: data)
                    print("PDF extract error!, statusCode: \(response.statusCode)")
                    print(errorResult.error)
                    completion(.failure(.corruptedPDF))
                    return
                }
                
                // 기타 요청 에러
                else if !(200 ..< 300 ~= response.statusCode) {
                    print("request error!, statusCode: \(response.statusCode)")
                    completion(.failure(.badRequest))
                    return
                }
            }
            
            let decoder = JSONDecoder()
            let decodedData = try decoder.decode(PDFLayoutResponseDTO.self, from: data)
            completion(.success(decodedData))
        } catch {
            print(String(describing: error))
        }
        
        
    }
    
    /// 에러 메시지 모델
    private struct ErrorDescription: Decodable {
        let error: String
    }
}
