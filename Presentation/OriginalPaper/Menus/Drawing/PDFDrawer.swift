//
//  PDFDrawer.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import Foundation
import PDFKit

enum DrawingTool: Int {
    case none = 0
    case eraser = 1
    case pencil = 2
    //TODO: - 올가미 (lasso)관련 설정 추가 
    
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

class PDFDrawer {
    
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation: DrawingAnnotation?
    private var currentPage: PDFPage?
    var penColor: PenColors = .black
    var drawingTool = DrawingTool.none
    private var eraserLayer: CAShapeLayer? = nil
    
    var onHistoryChange: (() -> Void)?

    var annotationHistory: [(action: PDFAction, annotation: PDFAnnotation, page: PDFPage)] = [] {
        didSet { onHistoryChange?() }
    }
    
    var redoStack: [(action: PDFAction, annotation: PDFAnnotation, page: PDFPage)] = [] {
        didSet { onHistoryChange?() }
    }
    
    // 히스토리에 저장
    private func addToHistory(action: PDFAction, annotation: PDFAnnotation, on page: PDFPage) {
        annotationHistory.append((action: action, annotation: annotation, page: page))

        // 주석 제한 : 10개
        if annotationHistory.count > 10 {
            annotationHistory.removeFirst()
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
//        annotationHistory.append(lastAction)
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
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        
        let pageBounds = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page)
        
        if pageBounds.contains(location) {
            let convertedPoint = pdfView.convert(location, to: currentPage!)
            path = UIBezierPath()
            path?.move(to: convertedPoint)
        }
    }
    
    // MARK: - 제스처 움직이는 동안 실행되는 함수
    func gestureRecognizerMoved(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        let pageBounds = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page)
        
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
    
    // MARK: - 패드에서 제스처 뗄 때 실행되는 함수
    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
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
}
