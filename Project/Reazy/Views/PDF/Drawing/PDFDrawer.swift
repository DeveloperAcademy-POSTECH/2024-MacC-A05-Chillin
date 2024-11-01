//
//  PDFDrawer.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import Foundation
import PDFKit

// 각종 그리기 도구와 관련된 부분, 지우개와 펜슬 둘 다 여기서 처리
// pencil과 highlighter는 추후 사용할 것 같아 주석처리만 했어요

enum DrawingTool: Int {
    case none = 0
    case eraser = 1
    case pencil = 2
    
    var width: CGFloat {
        switch self {
        case .eraser:
            return 5
        case .pencil:
            return 1
        default:
            return 0
        }
    }
    
    // 투명도
    var alpha: CGFloat {
        switch self {
        case .none:
            return 0
        default:
            return 1
        }
    }
}

class PDFDrawer {
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation : DrawingAnnotation?
    private var currentPage: PDFPage?
    var color = UIColor.init(hex: "#5F5CAB") // 펜 색상
    var drawingTool = DrawingTool.none
    private var eraserLayer: CAShapeLayer? = nil
}


extension PDFDrawer: DrawingGestureRecognizerDelegate {
    // 펜 처음 터치 했을 때 작동되는 함수
    func gestureRecognizerBegan(_ location: CGPoint) {
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        
        let pageBounds = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page)
        
         // 페이지 경계 내에서만 드로잉 시작
         if pageBounds.contains(location) {
             let convertedPoint = pdfView.convert(location, to: currentPage!)
             path = UIBezierPath()
             path?.move(to: convertedPoint)
         }
        
    }
    
    // 펜을 떼지 않고 움직이는 동안 작동되는 함수 - 조금이라도 움직일 때마다 호출
    func gestureRecognizerMoved(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        let pageBounds = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page).insetBy(dx: -5, dy: -5)
        
        // 페이지 경계를 벗어났다면 현재 경로를 완료하고 종료
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
            // 새로운 path 시작
            path = UIBezierPath()
            path?.move(to: convertedPoint)
        } else {
            path?.addLine(to: convertedPoint)
        }
        drawAnnotation(onPage: page)
    }

    private func completeCurrentPath(on page: PDFPage) {
        if let path = path {
            let finalAnnotation = createFinalAnnotation(path: path, page: page)
            page.addAnnotation(finalAnnotation)
            self.path = nil
            currentAnnotation = nil
        }
    }

    private func updateEraserLayer(at location: CGPoint) {
        if eraserLayer == nil {
            eraserLayer = CAShapeLayer()
            eraserLayer?.fillColor = UIColor(hex: "#EFEFF8").cgColor
            eraserLayer?.strokeColor = UIColor(hex: "#BABCCF").cgColor
            eraserLayer?.lineWidth = 1.0
            pdfView.layer.addSublayer(eraserLayer!)
        }
        
        let eraserCirclePath = UIBezierPath(arcCenter: location, radius: 14, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        eraserLayer?.path = eraserCirclePath.cgPath
    }

    
    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        // 지우개
        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: location, page: page)
            
            // 지우개 모양 제거
            eraserLayer?.removeFromSuperlayer()
            eraserLayer = nil
            return
        }
        
        // 드로잉
        guard let _ = currentAnnotation else { return }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        
        page.removeAnnotation(currentAnnotation!)
        let finalAnnotation = createFinalAnnotation(path: path!, page: page)
        currentAnnotation = nil
    }

    private func createAnnotation(path: UIBezierPath, page: PDFPage) -> DrawingAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        
        let annotation = DrawingAnnotation(bounds: page.bounds(for: pdfView.displayBox), forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
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
    
    private func createFinalAnnotation(path: UIBezierPath, page: PDFPage) -> PDFAnnotation {
        let border = PDFBorder()
        border.lineWidth = drawingTool.width
        
        let bounds = CGRect(x: path.bounds.origin.x - 5,
                            y: path.bounds.origin.y - 5,
                            width: path.bounds.size.width + 10,
                            height: path.bounds.size.height + 10)
        var signingPathCentered = UIBezierPath()
        signingPathCentered.cgPath = path.cgPath
        signingPathCentered.moveCenter(to: bounds.center)
        
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        annotation.add(signingPathCentered)
        page.addAnnotation(annotation)
                
        return annotation
    }
    
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        let convertedPoint = pdfView.convert(point, to: page)
        let hitTestRect = CGRect(x: convertedPoint.x - 3, y: convertedPoint.y - 3, width: 6, height: 6)
        
        let annotations = page.annotations.filter { annotation in
            return annotation.bounds.intersects(hitTestRect)
        }
        
        annotations.forEach { annotation in
            page.removeAnnotation(annotation)
        }
    }

    
    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
}
