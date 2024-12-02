//
//  PDFDrawer.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import Foundation
import PDFKit
import SwiftUI

enum DrawingTool: Int {
    case none = 0
    case eraser = 1
    case pencil = 2
    case lasso = 3
    case highlights = 4
    
    var width: CGFloat {
        switch self {
        case .eraser: return 5
        case .pencil: return 0.5
        default: return 0
        }
    }
    
    var alpha: CGFloat {
        switch self {
        case .none: return 0
        default: return 1
        }
    }
}

enum PDFAction {
    case add(PDFAnnotation)
    case remove(PDFAnnotation)
}

enum Storage {
    case figure
    case collection
}

class PDFDrawer {
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    @Published var drawingTool: DrawingTool = .none
    
    @Published var selectedStorage: Storage = .figure
    
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation: DrawingAnnotation?
    private var currentPage: PDFPage?
    var penColor: PenColors = .black

    private var eraserLayer: CAShapeLayer? = nil
    
    var onHistoryChange: (() -> Void)?
    
    var startPoint: CGPoint? // lasso 영역을 저장할 경로 추가
    var endPoint: CGPoint? // lasso 영역을 저장할 경로 추가
    var checkButton: UIButton = UIButton()
    
    private var lassoRectangleLayer: CAShapeLayer? // 점선 사각형을 그리기 위한 레이어
    
    var annotationHistory: [(action: PDFAction, annotation: PDFAnnotation, page: PDFPage)] = [] {
        didSet { onHistoryChange?() }
    }
    
    var redoStack: [(action: PDFAction, annotation: PDFAnnotation, page: PDFPage)] = [] {
        didSet { onHistoryChange?() }
    }
    
    // 올가미로 선택한 영역 좌표
    @State private var selectedRect: CGRect = .zero
    
    // 새로운 주석 히스토리에 저장
    private func addToHistory(action: PDFAction, annotation: PDFAnnotation, on page: PDFPage) {
        annotationHistory.append((action: action, annotation: annotation, page: page))
        
        // 최신 10개만 남기기
        if annotationHistory.count > 10 {
            annotationHistory = Array(annotationHistory.suffix(10))
        }
        
        redoStack.removeAll()
    }
    
    func undo() {
        guard !annotationHistory.isEmpty else { return }
        
        let lastAction = annotationHistory.removeLast()
        
        switch lastAction.action {
        case .add(let annotation):
            lastAction.page.removeAnnotation(annotation)
            
        case .remove(let annotation):
            lastAction.page.addAnnotation(annotation)
        }
        redoStack.append(lastAction)
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        let lastAction = redoStack.removeLast()
        
        switch lastAction.action {
        case .add(let annotation):
            lastAction.page.addAnnotation(annotation)
        case .remove(let annotation):
            lastAction.page.removeAnnotation(annotation)
        }
        annotationHistory.append(lastAction)
    }
    
    // 주석 추가
    func addAnnotation(_ annotation: PDFAnnotation, page: PDFPage) {
        page.addAnnotation(annotation)
        annotationHistory.append((action: .add(annotation), annotation: annotation, page: page))
    }
    
    // 주석 삭제
    func removeAnnotation(_ annotation: PDFAnnotation, page: PDFPage) {
        page.removeAnnotation(annotation)
        redoStack.append((action: .remove(annotation), annotation: annotation, page: page))
    }
}

extension PDFDrawer: DrawingGestureRecognizerDelegate {
    // MARK: - 제스처 최초 시작 시 한 번 실행되는 함수
    func gestureRecognizerBegan(_ location: CGPoint) {
        if drawingTool == .none { return }
        
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page

        if drawingTool == .lasso {
            
            lassoRectangleLayer?.removeFromSuperlayer()
            checkButton.removeFromSuperview()
            
            if checkButton.frame.contains(location) {
                // 버튼을 터치했으면 제스처를 시작하지 않음
                return
            }
            // 터치 시작 시점에서 사각형의 왼쪽 상단 좌표를 저장
            startPoint = location  // 시작점 설정

            // 점선 테두리 레이어를 준비
            lassoRectangleLayer = CAShapeLayer()
            lassoRectangleLayer?.strokeColor = UIColor.primary1.cgColor // 점선 색상 설정
            lassoRectangleLayer?.lineWidth = 1.5
            lassoRectangleLayer?.lineDashPattern = [6, 6] // 점선
            lassoRectangleLayer?.fillColor = UIColor.init(hex: "CFD9FF").withAlphaComponent(0.2).cgColor // 하늘색 채우기
            pdfView.layer.addSublayer(lassoRectangleLayer!)
            return
        }
        
        let pageBounds = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page)
        
        if pageBounds.contains(location) {
            let convertedPoint = pdfView.convert(location, to: currentPage!)
            path = UIBezierPath()
            path?.move(to: convertedPoint)
        }
        
    }
    
    // MARK: - 제스처 움직이는 동안 실행되는 함수
    func gestureRecognizerMoved(_ location: CGPoint) {
        if drawingTool == .none { return }
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        let pageBounds = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page)
        
        if drawingTool == .lasso {
            guard let startPoint = self.startPoint else { return }

            // 현재 위치에 따라 실시간으로 사각형의 위치와 크기를 계산
            let topLeft = CGPoint(x: min(startPoint.x, location.x), y: max(startPoint.y, location.y))
            let bottomRight = CGPoint(x: max(startPoint.x, location.x), y: min(startPoint.y, location.y))
            
            let width = bottomRight.x - topLeft.x
            let height = bottomRight.y - topLeft.y
            
            // 사각형 경로를 업데이트
            let rectanglePath = UIBezierPath(rect: CGRect(x: topLeft.x, y: topLeft.y, width: width, height: height))
            
            // CAShapeLayer의 경로를 업데이트하여 화면에 실시간으로 변경된 사각형이 보이도록 설정
            lassoRectangleLayer?.path = rectanglePath.cgPath
            return
        }
        
        if !pageBounds.contains(location) {
            completeCurrentPath(on: page)
            return
        }
        
        if drawingTool == .eraser {
            updateEraserLayer(at: location)
            removeAnnotationAtPoint(point: location, page: page)
            return
        }
        
        if path == nil {
            path = UIBezierPath()
            path?.move(to: convertedPoint)
        } else {
            path?.addLine(to: convertedPoint)
        }
        drawAnnotation(onPage: page)
    }
    
    // MARK: - 패드에서 제스처 뗄 때 실행되는 함수
    func gestureRecognizerEnded(_ location: CGPoint) {
        if drawingTool == .none { return }
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        if drawingTool == .lasso {
            if checkButton.frame.contains(location) {
                // MARK: PDF 저장하는 부분
                guard let startConvertedPoint = self.startPoint else { return }
                guard let endConvertedPoint = self.endPoint else { return }
                
                let topLeft = CGPoint(x: min(startConvertedPoint.x, endConvertedPoint.x),
                                      y: max(startConvertedPoint.y, endConvertedPoint.y))
                let bottomRight = CGPoint(x: max(startConvertedPoint.x, endConvertedPoint.x),
                                          y: min(startConvertedPoint.y, endConvertedPoint.y))
                
                let width = bottomRight.x - topLeft.x
                let height = topLeft.y - bottomRight.y
                
                let rectanglePath = UIBezierPath(rect: CGRect(x: topLeft.x, y: topLeft.y, width: width, height: height))

                if let newFigure = captureToPDF(path: rectanglePath) {
                    print("PDF is captured: \(newFigure)")
                    endCaptureMode()
                }
                
                let totalPageCount = PDFSharedData.shared.document?.pageCount ?? 0
                print("🔔 current page Index : \(PDFSharedData.shared.document?.index(for: page) ?? 0)")
                let pageNum = min(PDFSharedData.shared.document?.index(for: page) ?? 0, totalPageCount - 1)
                
                let pageHeight = PDFSharedData.shared.document!.page(at: 0)!.bounds(for: .mediaBox).height
                
                let coords = "\(pageNum + 1),\(topLeft.x),\(pageHeight - bottomRight.y),\(width),\(-height)"
                
                if selectedStorage == .figure {
                    let result = Figure(id: "New", head: "New", coords: [coords])
                    
                    NotificationCenter.default.post(name: .isFigureCaptured, object: result)
                } else {
                    let result = Figure(id: "Bookmark", head: "Bookmark", coords: [coords])
                    
                    NotificationCenter.default.post(name: .isCollectionCaptured, object: result)
                }
                
                return
            }
            
            guard let startPoint = self.startPoint else { return }

            // 현재 위치에 따라 실시간으로 사각형의 위치와 크기를 계산
            let topLeft = CGPoint(x: min(startPoint.x, location.x), y: min(startPoint.y, location.y))
            let bottomRight = CGPoint(x: max(startPoint.x, location.x), y: max(startPoint.y, location.y))
            
            let width = bottomRight.x - topLeft.x
            let height = bottomRight.y - topLeft.y
            
            // 사각형 경로를 생성
            let rectanglePath = UIBezierPath(rect: CGRect(x: topLeft.x, y: topLeft.y, width: width, height: height))
            
            lassoRectangleLayer?.path = rectanglePath.cgPath
            
            // 좌표 pdf에 맞게 변경
            self.startPoint = pdfView.convert(startPoint, to: page)
            self.endPoint = pdfView.convert(location, to: page)
            
            // 올가미 하단에 뜨는 체크 버튼
            checkButton = UIButton(type: .system)
            checkButton.frame = CGRect(x: topLeft.x + width / 2 - 18, y: topLeft.y + height + 8, width: 36, height: 28)
            checkButton.setImage(UIImage(named: "check"), for: .normal) // 버튼 이미지 설정
            checkButton.imageView?.contentMode = .scaleAspectFit
            checkButton.tintColor = .gray100
            checkButton.backgroundColor = .point4
            checkButton.layer.cornerRadius = 10
            pdfView.addSubview(checkButton)

            return
            
        }
        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: location, page: page)
            eraserLayer?.removeFromSuperlayer()
            eraserLayer = nil
            return
        }
        
        guard let _ = currentAnnotation else { return }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        page.removeAnnotation(currentAnnotation!)
        
        if drawingTool == .pencil {
            let _ = createFinalAnnotation(path: path!, page: page)
        }
        currentAnnotation = nil
    }
    
    private func completeCurrentPath(on page: PDFPage) {
        guard let path = path else { return }
        let finalAnnotation = createFinalAnnotation(path: path, page: page)
        page.addAnnotation(finalAnnotation)
        self.path = nil
        currentAnnotation = nil
    }
    
    private func updateEraserLayer(at location: CGPoint) {
        // 지우개 레이어가 없다면 새로 생성
        if eraserLayer == nil {
            eraserLayer = CAShapeLayer()
            eraserLayer?.fillColor = UIColor(hex: "#EFEFF8").cgColor
            eraserLayer?.strokeColor = UIColor(hex: "#BABCCF").cgColor
            eraserLayer?.lineWidth = 1.0
            pdfView.layer.addSublayer(eraserLayer!)
        }
        
        // 확대 축소 비율 고려해서 지우개 모양 만들기
        let scaleFactor = pdfView.scaleFactor
        let eraserRadius = 5 * scaleFactor
        let eraserCirclePath = UIBezierPath(arcCenter: location, radius: eraserRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        eraserLayer?.path = eraserCirclePath.cgPath
    }
    
    private func createAnnotation(path: UIBezierPath, page: PDFPage) -> DrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        
        let annotation = DrawingAnnotation(bounds: page.bounds(for: pdfView.displayBox), forType: .ink, withProperties: nil)
        // 펜 디자인 설정
        annotation.color = penColor.uiColor.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        return annotation
    }
    
    private func drawAnnotation(onPage: PDFPage) {
        guard let path = path else { return }
        
        if currentAnnotation == nil {
            currentAnnotation = createAnnotation(path: path, page: onPage)
        }
        
        currentAnnotation?.path = path
        forceRedraw(annotation: currentAnnotation!, onPage: onPage)
    }
    
    // MARK: -획을 그리고 배열에 저장하는 함수
    private func createFinalAnnotation(path: UIBezierPath, page: PDFPage) -> PDFAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        
        let bounds = CGRect(x: path.bounds.origin.x - 5,
                            y: path.bounds.origin.y - 5,
                            width: path.bounds.size.width + 10,
                            height: path.bounds.size.height + 10)
        let signingPathCentered = UIBezierPath()
        signingPathCentered.cgPath = path.cgPath
        let _ = signingPathCentered.moveCenter(to: bounds.center)
        
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = penColor.uiColor.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        annotation.add(signingPathCentered)
        page.addAnnotation(annotation)
        
        addToHistory(action: PDFAction.add(annotation), annotation: annotation, on: page)
        
        return annotation
    }
    
    // MARK: - 지우개로 주석 지울 때 실행되는 함수
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        let convertedPoint = pdfView.convert(point, to: page)
        let scaleFactor = pdfView.scaleFactor
        let scaledRadius = 5 / scaleFactor
        let hitTestRect = CGRect(x: convertedPoint.x - scaledRadius, y: convertedPoint.y - scaledRadius, width: scaledRadius * 2, height: scaledRadius * 2)
        
        let annotations = page.annotations.filter { annotation in
            annotation.bounds.intersects(hitTestRect)
        }
        
        if (pdfView.document?.index(for: page)) != nil {
            for annotation in annotations {
                // 하이라이트랑 드로잉만 지우기
                if annotation.type == "Ink" || (annotation.type == "Highlight" && annotation.value(forAnnotationKey: .contents) == nil) {
                    _ = annotation.bounds
                    
                    annotationHistory.append((action: .remove(annotation), annotation: annotation, page: page))
                    page.removeAnnotation(annotation)
                }
            }
        }
    }
    
    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
    
    // 올가미 영역을 PDF Document로 바꿔주는 함수
    private func captureToPDF(path: UIBezierPath) -> PDFDocument? {
        guard let page = currentPage else { return nil }
        
        let clipRect = path.bounds
        let pageBounds = page.bounds(for: pdfView.displayBox)

        guard pageBounds.intersects(clipRect) else { return nil }

        let croppedRect = pageBounds.intersection(clipRect)

        // 새 PDF 문서 만들기
        let document = PDFDocument()
        let newPage = page.copy() as! PDFPage
        newPage.setBounds(croppedRect, for: .mediaBox)
        document.insert(newPage, at: 0)

        return document
    }
    
    func endCaptureMode() {
        drawingTool = .none
        lassoRectangleLayer?.removeFromSuperlayer()
        checkButton.removeFromSuperview()
    }
}
