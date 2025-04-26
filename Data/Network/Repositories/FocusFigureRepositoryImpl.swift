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
        // 1. PDF 데이터 로드
        guard let pdfData = try? Data(contentsOf: url) else {
            completion(.failure(.invalidPDF))
            return
        }
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            completion(.failure(.invalidPDF))
            return
        }

        // 2. PDF 페이지를 UIImage/CIImage로 변환
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

        // 3. CoreML 모델 객체화
        guard let yoloModel = try? VNCoreMLModel(for: best().model) else {
            completion(.failure(.badRequest))
            return
        }

        var detectedFigures: [Figure] = []

        // 4. 각 페이지 ML 수행
        for (pageIndex, imagePair) in imagePairs.enumerated() {
            var mlResults: [VNRecognizedObjectObservation] = []
            
            let mlRequest = VNCoreMLRequest(model: yoloModel) { request, _ in
                if let results = request.results as? [VNRecognizedObjectObservation] {
                    mlResults = results
                }
            }
            
            let mlHandler = VNImageRequestHandler(ciImage: imagePair.ciImage, options: [:])
            try? mlHandler.perform([mlRequest])

            // 5. 객체를 상단에서 하단 순으로 정렬 (한 페이지 내에서 순서가 뒤죽박죽 이슈)
            let sortedResults = mlResults.sorted {
                let height = imagePair.uiImage.size.height
                let y1 = (1 - $0.boundingBox.origin.y - $0.boundingBox.size.height) * height
                let y2 = (1 - $1.boundingBox.origin.y - $1.boundingBox.size.height) * height
                return y1 < y2
            }

            // 6. 각 이미지 하나하나 처리
            for (detectionIndex, observation) in sortedResults.enumerated() {
                let boundingBox = observation.boundingBox
                let uiImage = imagePair.uiImage
                let width = uiImage.size.width
                let height = uiImage.size.height
                
                var x = boundingBox.origin.x * width
                var y = (1 - boundingBox.origin.y - boundingBox.size.height) * height
                var w = boundingBox.size.width * width
                var h = boundingBox.size.height * height

                var recognizedText = ""

                // 7. 이미지 상단 여백 감지 후 늘리기
                if let cgImage = uiImage.cgImage {
                    let scaleX = CGFloat(cgImage.width) / width
                    let scaleY = CGFloat(cgImage.height) / height
                    
                    var cropRect = CGRect(
                        x: x * scaleX,
                        y: y * scaleY,
                        width: w * scaleX,
                        height: h * scaleY
                    )
                    
                    cropRect = extendCropRectUpwards(in: cgImage, initialCropRect: cropRect)
                    
                    x = cropRect.origin.x / scaleX
                    y = cropRect.origin.y / scaleY
                    w = cropRect.width / scaleX
                    h = cropRect.height / scaleY

                    // 8. 최종 잘린 이미지 OCR
                    if let finalCropped = cgImage.cropping(to: cropRect) {
                        recognizedText = performOCR(on: finalCropped)
                    }
                }

                // 9. Figure 정보 추출 (pageIndex +1 해준 이유는 인덱스가 1부터 시작하는 듯 하여 +1 해줌)
                let headValue = extractFigureTitle(from: recognizedText)
                let coordString = "\(pageIndex+1),\(x),\(y),\(w),\(h)"
                
                let figure = Figure(
                    id: "figure_\(pageIndex)_\(detectionIndex)",
                    head: headValue,
                    coords: [coordString]
                )
                detectedFigures.append(figure)
            }
        }

        // 10. 최종 결과 반환
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

// MARK: - Figure 추출 Helper Functions
extension FocusFigureRepositoryImpl {
    private func extendCropRectUpwards(in cgImage: CGImage, initialCropRect: CGRect) -> CGRect {
        var cropRect = initialCropRect

        while Int(cropRect.origin.y) > 0 {
            let newY = Int(cropRect.origin.y) - 1
            let rowRect = CGRect(x: Int(cropRect.origin.x),
                                 y: newY,
                                 width: Int(cropRect.width),
                                 height: 1)
            guard let rowImage = cgImage.cropping(to: rowRect) else { break }
            
            if isImageRowWhite(rowImage) {
                cropRect.origin.y = CGFloat(newY)
                cropRect.size.height += 1
                break
            } else {
                cropRect.origin.y = CGFloat(newY)
                cropRect.size.height += 1
            }
        }
        return cropRect
    }

    private func isImageRowWhite(_ cgImage: CGImage) -> Bool {
        let width = cgImage.width
        let height = cgImage.height
        
        var pixelData = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return false
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let whiteThreshold: UInt8 = 250
        for pixel in pixelData {
            if pixel < whiteThreshold {
                return false
            }
        }
        return true
    }

    private func performOCR(on cgImage: CGImage) -> String {
        var recognizedText = ""
        var ocrResults: [VNRecognizedTextObservation] = []
        
        let ocrRequest = VNRecognizeTextRequest { request, _ in
            ocrResults = request.results as? [VNRecognizedTextObservation] ?? []
        }
        ocrRequest.recognitionLevel = .accurate
        
        let ocrHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? ocrHandler.perform([ocrRequest])
        
        recognizedText = ocrResults.compactMap {
            $0.topCandidates(1).first?.string
        }.joined(separator: " ")
        
        return recognizedText
    }

    private func extractFigureTitle(from text: String) -> String {
        let pattern = "(?i)(?:figure|fig|table|tab)[ _]+(?:\\d+[A-Za-z]?|[A-Za-z])(?:[._](?:\\d+[A-Za-z]?|[A-Za-z]))*\\.?|[A-Za-z]+_[\\dA-Za-z]+\\.?"
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return "Figure"
    }
}
