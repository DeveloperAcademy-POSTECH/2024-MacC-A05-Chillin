//
//  PDFDrawer.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import Foundation
import PDFKit

// pencil과 highlighter는 버전 2에서 사용할 것 같아 없애지 않았어요

enum DrawingTool: Int {
    case none = 0
    case eraser = 1
    case pencil = 2
    case pen = 3
    case highlighter = 4
    
    var width: CGFloat {
        switch self {
        case .eraser:
            return 7
        case .pencil:
            return 1
        case .pen:
            return 8
        case .highlighter:
            return 10
        default:
            return 0
        }
    }
    
    var alpha: CGFloat {
        switch self {
        case .highlighter:
            return 0.3 //0,5
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
    var color = UIColor.init(hex: "#727BC7")
    var drawingTool = DrawingTool.none
}

extension PDFDrawer: DrawingGestureRecognizerDelegate {
    func gestureRecognizerBegan(_ location: CGPoint) {
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)
        path = UIBezierPath()
        path?.move(to: convertedPoint)
    }
    
    func gestureRecognizerMoved(_ location: CGPoint) {

        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        if drawingTool == .eraser {
            let eraserCirclePath = UIBezierPath(arcCenter: location, radius: 14, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            
            // 실시간 지우개 위치를 표시하는 회색 테두리의 동그란 원
            let eraserLayer = CAShapeLayer()
            eraserLayer.path = eraserCirclePath.cgPath
            eraserLayer.fillColor = UIColor(hex: "#EFEFF8").cgColor
            eraserLayer.strokeColor = UIColor(hex: "#BABCCF").cgColor
            eraserLayer.lineWidth = 1.0
        
            pdfView.layer.addSublayer(eraserLayer)
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                eraserLayer.removeFromSuperlayer()
            }
            
            // 지우개 기능
            removeAnnotationAtPoint(point: location, page: page)
            return
        }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        drawAnnotation(onPage: page)
    }
    
    func gestureRecognizerEnded(_ location: CGPoint) {
        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)
        
        // Erasing
        if drawingTool == .eraser {
            removeAnnotationAtPoint(point: location, page: page)
            return
        }
        
        // Drawing
        guard let _ = currentAnnotation else { return }
        
        path?.addLine(to: convertedPoint)
        path?.move(to: convertedPoint)
        
        // Final annotation
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
        let hitTestRect = CGRect(x: convertedPoint.x - 5, y: convertedPoint.y - 5, width: 10, height: 10)
        
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
