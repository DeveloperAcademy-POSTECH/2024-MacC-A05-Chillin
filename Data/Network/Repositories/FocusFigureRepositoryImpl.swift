//
//  FocusFigureRepositoryImpl.swift
//  Reazy
//
//  Created by 문인범 on 11/15/24.
//

import Foundation
import Combine
import PDFKit
import CoreML
import Vision


class FocusFigureRepositoryImpl: FocusFigureRepository {
    private let baseProcess: NetworkManager.ServiceName
    
    
    init(baseProcess: NetworkManager.ServiceName) {
        self.baseProcess = baseProcess
    }
    
    
    /// 조니: 내부 CoreML을 통해서 Figure 추출 (임시로 함수 오버로드)
    func fetchFocusAndFigures(
        url: URL,
        completion: @escaping (Result<PDFLayoutResponseDTO, NetworkManagerError>) -> Void
    ) {
        // URL로부터 PDF 데이터 로드
        guard let pdfData = try? Data(contentsOf: url) else {
            completion(.failure(.invalidPDF))
            return
        }
        
        // PDF 데이터를 PDFDocument 변환
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            completion(.failure(.invalidPDF))
            return
        }
        
        // PDF의 UIImage와 CIImage 튜플로 변환
        var imagePairs: [(uiImage: UIImage, ciImage: CIImage)] = []
        
        for index in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: index) else { continue }
            
            let pageRect = page.bounds(for: .mediaBox)
            
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(pageRect)
                
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
            
            if let ciImage = image.ciImage ?? CIImage(image: image) {
                imagePairs.append((uiImage: image, ciImage: ciImage))
            }
        }
        
        // 감지된 Figure가 담기는 배열
        var detectedFigures: [Figure] = []
        
        // 모든 페이지 처리가 끝날 때까지 대기하기 위한 DispatchGroup
        let dispatchGroup = DispatchGroup()
        
        // YOLO 모델 로드
        guard let yoloModel = try? VNCoreMLModel(for: best().model) else {
            completion(.failure(.badRequest))
            return
        }
        
        // for 문 돌면서 각 이미지에 대해 좌표 변환 후 데이터 생성
        for (pageIndex, imagePair) in imagePairs.enumerated() {
            dispatchGroup.enter()
            
            let request = VNCoreMLRequest(model: yoloModel) { (request, error) in
                if let results = request.results as? [VNRecognizedObjectObservation] {
                    // 각 객체에 대해 y값 기준 오름차순 정렬 (상단 객체가 먼저 나오도록)
                    let sortedResults = results.sorted { (obs1, obs2) -> Bool in
                        let height = imagePair.uiImage.size.height
                        let y1 = (1 - obs1.boundingBox.origin.y - obs1.boundingBox.size.height) * height
                        let y2 = (1 - obs2.boundingBox.origin.y - obs2.boundingBox.size.height) * height
                        return y1 < y2
                    }
                    
                    // 각 감지된 객체마다 별도의 Figure 인스턴스를 생성
                    for (detectionIndex, observation) in sortedResults.enumerated() {
                        let boundingBox = observation.boundingBox
                        let uiImage = imagePair.uiImage
                        let width = uiImage.size.width
                        let height = uiImage.size.height
                        let x = boundingBox.origin.x * width
                        let y = (1 - boundingBox.origin.y - boundingBox.size.height) * height
                        let w = boundingBox.size.width * width
                        let h = boundingBox.size.height * height
                        
                        // FigureView의 pageIndex가 1로 시작하는 듯 하여 +1 해줍니다.
                        let coordString = "\(pageIndex+1),\(x),\(y),\(w),\(h)"
                        
                        // 각각의 감지된 객체를 별도의 Figure로 생성 (coords 배열에 단일 좌표 포함)
                        let figure = Figure(id: "figure_\(pageIndex)_\(detectionIndex)", head: "Detected Page \(pageIndex) - \(detectionIndex+1)", coords: [coordString])
                        
                        detectedFigures.append(figure)
                    }
                }
                dispatchGroup.leave()
            }
            
            let handler = VNImageRequestHandler(ciImage: imagePair.ciImage, options: [:])
            DispatchQueue.global().async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Error performing request: \(error)")
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let pdfLayout = PDFLayoutResponseDTO(div: [], fig: detectedFigures, table: nil)
            completion(.success(pdfLayout))
        }
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
//                    let errorResult = try? decoder.decode(ErrorDescription.self, from: data)
                    print("PDF extract error!, statusCode: \(response.statusCode)")
//                    print(errorResult.error)
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
