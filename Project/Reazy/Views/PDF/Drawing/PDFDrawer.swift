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
    
    var width: CGFloat {
        switch self {
        case .eraser: return 5
        case .pencil: return 1
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

class PDFDrawer {
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation: DrawingAnnotation?
    private var currentPage: PDFPage?
    var color = UIColor(hex: "#5F5CAB")
    var drawingTool = DrawingTool.none
    private var eraserLayer: CAShapeLayer? = nil
    private var drawingDataArray: [Drawing] = []

    private func saveAndAddAnnotation(_ path: UIBezierPath, on page: PDFPage) {
        let finalAnnotation = createFinalAnnotation(path: path, page: page)
        page.addAnnotation(finalAnnotation)

        if let pageIndex = pdfView.document?.index(for: page) {
            let drawingData = Drawing(id: UUID(), pageIndex: pageIndex, path: path, color: color)
            drawingDataArray.append(drawingData)
        }
    }
}

extension PDFDrawer: DrawingGestureRecognizerDelegate {
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
        let signingPathCentered = UIBezierPath()
        signingPathCentered.cgPath = path.cgPath
        let _ = signingPathCentered.moveCenter(to: bounds.center)
        
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        annotation.color = color.withAlphaComponent(drawingTool.alpha)
        annotation.border = border
        annotation.add(signingPathCentered)
        page.addAnnotation(annotation)
        
        if drawingTool == .pencil {
            if let pageIndex = pdfView.document?.index(for: page) {
                let drawingData = Drawing(id: UUID(), pageIndex: pageIndex, path: path, color: color)
                drawingDataArray.append(drawingData)
                print("array count after append: \(drawingDataArray.count)")
            }
        }
        
        return annotation
    }
    
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        let convertedPoint = pdfView.convert(point, to: page)
        let hitTestRect = CGRect(x: convertedPoint.x - 3, y: convertedPoint.y - 3, width: 6, height: 6)

        let annotations = page.annotations.filter { annotation in
            annotation.bounds.intersects(hitTestRect)
        }

        if let pageIndex = pdfView.document?.index(for: page) {
            for annotation in annotations {
                let annotationBounds = annotation.bounds
                
                let indicesToRemove = drawingDataArray.indices.filter { index in
                    let drawing = drawingDataArray[index]
                    return drawing.pageIndex == pageIndex && drawing.path.bounds.intersects(annotationBounds)
                }

                for index in indicesToRemove.reversed() {
                    drawingDataArray.remove(at: index)
                    print("array count after remove: \(drawingDataArray.count)")
                }

                page.removeAnnotation(annotation)
            }
        }
    }

    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
    
    func loadDrawings() {
        pdfView.goToFirstPage(nil)
        
        guard let document = pdfView.document else { return }
        
        for drawing in drawingDataArray {
            guard let page = document.page(at: drawing.pageIndex) else { continue }
            let annotation = createFinalAnnotation(path: drawing.path, page: page)
            annotation.color = drawing.color
            page.addAnnotation(annotation)
        }
        
        pdfView.setNeedsDisplay()
    }
}
