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
    
    
    /// 조니: 내부 CoreML을 통해서 Figure 추출 (임시로 함수 오버로드, 추후에 완벽 동작 시 코드 대체)
    func fetchFocusAndFigures(
        url: URL,
        completion: @escaping (Result<PDFLayoutResponseDTO, NetworkManagerError>) -> Void
    ) {
        guard let pdfData = try? Data(contentsOf: url) else {
            completion(.failure(.invalidPDF))
            return
        }
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            completion(.failure(.invalidPDF))
            return
        }
        
        // PDF의 UIImage와 CIImage 튜플로 변환 (CoreML은 기본적으로 이미지가 입력 값임)
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
        
        var detectedFigures: [Figure] = []
        
        // YOLO 모델 로드 (Resource의 CoreML 폴더 내 best 파일)
        guard let yoloModel = try? VNCoreMLModel(for: best().model) else {
            completion(.failure(.badRequest))
            return
        }
        
        // for문 돌려서 감지 결과 처리 (비동기로 처리하려 했으나, 감지가 안끝나는 문제로 일단 For문으로 수행. 시간 줄이려면 비동기로 해야됨)
        for (pageIndex, imagePair) in imagePairs.enumerated() {
            var mlResults: [VNRecognizedObjectObservation] = []
            
            let mlRequest = VNCoreMLRequest(model: yoloModel) { (request, error) in
                if let results = request.results as? [VNRecognizedObjectObservation] {
                    mlResults = results
                } else {
                    print("ML 감지 결과 없음 for page \(pageIndex)")
                }
            }
            
            let mlHandler = VNImageRequestHandler(ciImage: imagePair.ciImage, options: [:])
            do {
                try mlHandler.perform([mlRequest])
            } catch {
                print("ML 요청 수행 중 에러: \(error)")
                continue
            }
            
            // 같은 페이지 내에서 하단 객체가 먼저 나와서 상단 객체가 먼저 나오도록 재정렬
            let sortedResults = mlResults.sorted { (obs1, obs2) -> Bool in
                let height = imagePair.uiImage.size.height
                let y1 = (1 - obs1.boundingBox.origin.y - obs1.boundingBox.size.height) * height
                let y2 = (1 - obs2.boundingBox.origin.y - obs2.boundingBox.size.height) * height
                return y1 < y2
            }
            
            // OCR
            for (detectionIndex, observation) in sortedResults.enumerated() {
                let boundingBox = observation.boundingBox
                let uiImage = imagePair.uiImage
                let width = uiImage.size.width
                let height = uiImage.size.height
                let x = boundingBox.origin.x * width
                let y = (1 - boundingBox.origin.y - boundingBox.size.height) * height
                let w = boundingBox.size.width * width
                let h = boundingBox.size.height * height
                
                var recognizedText = ""
                if let cgImage = uiImage.cgImage {
                    let scaleX = CGFloat(cgImage.width) / width
                    let scaleY = CGFloat(cgImage.height) / height
                    let cropRect = CGRect(x: x * scaleX,
                                          y: y * scaleY,
                                          width: w * scaleX,
                                          height: h * scaleY)
                    
                    if let croppedCGImage = cgImage.cropping(to: cropRect) {
                        var ocrResults: [VNRecognizedTextObservation] = []
                        let ocrRequest = VNRecognizeTextRequest { (request, error) in
                            if let observations = request.results as? [VNRecognizedTextObservation] {
                                ocrResults = observations
                            } else {
                                print("OCR 결과 없음 for figure_\(pageIndex)_\(detectionIndex)")
                            }
                        }
                        ocrRequest.recognitionLevel = .accurate
                        
                        let ocrHandler = VNImageRequestHandler(cgImage: croppedCGImage, options: [:])
                        do {
                            try ocrHandler.perform([ocrRequest])
                        } catch {
                            print("OCR 요청 수행 중 에러: \(error)")
                        }
                        
                        recognizedText = ocrResults.compactMap { $0.topCandidates(1).first?.string }
                            .joined(separator: " ")
                        print("전체 OCR 결과 for figure_\(pageIndex)_\(detectionIndex): \(recognizedText)")
                    }
                }
                
                // 정규표현식 패턴 (추가할 수 있으면 추가하는게 좋음. 회의 필요할지도)
                // (?i) : 대소문자 구분 없이
                // (?:figure|fig|table|tab) : 해당 단어들 중 하나로 시작
                // [ _]+ : 하나 이상의 공백 또는 언더바
                // (?:\d+[A-Za-z]?|[A-Za-z]) : 숫자와 선택적 영문자, 또는 영문자 단독
                // (?:[._](?:\d+[A-Za-z]?|[A-Za-z]))* : 추가로 점 또는 언더바로 구분된 숫자/문자 조합(여러번 반복 가능)
                // \.? : 마지막에 점이 있을 수 있음
                // 또는 기존의 [A-Za-z]+_[\dA-Za-z]+\.? 형식
                let pattern = "(?i)(?:figure|fig|table|tab)[ _]+(?:\\d+[A-Za-z]?|[A-Za-z])(?:[._](?:\\d+[A-Za-z]?|[A-Za-z]))*\\.?|[A-Za-z]+_[\\dA-Za-z]+\\.?"
                
                var headValue = ""
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let range = NSRange(location: 0, length: recognizedText.utf16.count)
                    let matches = regex.matches(in: recognizedText, options: [], range: range)
                    if !matches.isEmpty {
                        var extracted = [String]()
                        for match in matches {
                            if let matchRange = Range(match.range, in: recognizedText) {
                                extracted.append(String(recognizedText[matchRange]))
                            }
                        }
                        headValue = extracted.joined(separator: ", ")
                    }
                }
                // 정규식에 의해 추출된 값이 없으면 "Figure"로 기본값
                if headValue.isEmpty {
                    headValue = "Figure"
                }
                
                // 페이지 번호가 1부터 시작하는 듯 하여 +1 처리 해줌 (추후에 리팩토링 할 필요가 있어보임)
                let coordString = "\(pageIndex+1),\(x),\(y),\(w),\(h)"
                let figure = Figure(id: "figure_\(pageIndex)_\(detectionIndex)",
                                    head: headValue,
                                    coords: [coordString])
                detectedFigures.append(figure)
            }
        }
        
        // 처리가 완료되면 completion
        let pdfLayout = PDFLayoutResponseDTO(div: [], fig: detectedFigures, table: nil)
        completion(.success(pdfLayout))
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
