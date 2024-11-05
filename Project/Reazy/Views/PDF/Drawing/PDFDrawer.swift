//
//  PDFDrawer.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import Foundation
import PDFKit

// 각종 그리기 도구와 관련된 부분, 지우개와 펜슬 둘 다 여기서 처리

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
    
    private var drawingDataArray: [Drawing] = []
    
    // 드로잉 데이터를 배열에 추가하고 주석을 페이지에 추가하는 함수
    private func saveAndAddAnnotation(_ path: UIBezierPath, on page: PDFPage) {
        let finalAnnotation = createFinalAnnotation(path: path, page: page)
        page.addAnnotation(finalAnnotation)
        
        // 드로잉 데이터를 배열에 추가
        if let pageIndex = pdfView.document?.index(for: page) {
            let drawingData = Drawing(id: UUID(), pageIndex: pageIndex, path: path, color: color)
            drawingDataArray.append(drawingData)
        }
    }
    
    
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
        
        let pageBounds = pdfView.convert(page.bounds(for: pdfView.displayBox), from: page)
        
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
        let _ = createFinalAnnotation(path: path!, page: page)
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
        
        // 완료된 그리기를 drawingDataArray에 추가
        if let pageIndex = pdfView.document?.index(for: page) {
            let drawingData = Drawing(id: UUID(), pageIndex: pageIndex, path: path, color: color)
            drawingDataArray.append(drawingData)
            print(drawingDataArray.count)
        }
        
        return annotation
    }
    
    private func removeAnnotationAtPoint(point: CGPoint, page: PDFPage) {
        let convertedPoint = pdfView.convert(point, to: page)
        let hitTestRect = CGRect(x: convertedPoint.x - 3, y: convertedPoint.y - 3, width: 6, height: 6)

        // 해당 위치의 주석을 찾음
        let annotations = page.annotations.filter { annotation in
            annotation.bounds.intersects(hitTestRect)
        }

        if let pageIndex = pdfView.document?.index(for: page) {
            for annotation in annotations {
                let annotationBounds = annotation.bounds
                
                // 관련된 모든 드로잉의 인덱스를 찾기
                let indicesToRemove = drawingDataArray.indices.filter { index in
                    let drawing = drawingDataArray[index]
                    let intersects = drawing.pageIndex == pageIndex && drawing.path.bounds.intersects(annotationBounds)
                    
                    // 디버깅 로그
                    if intersects {
                        print("Drawing at index \(index) matches with annotation. Drawing bounds: \(drawing.path.bounds), Annotation bounds: \(annotationBounds)")
                    } else {
                        print("Drawing at index \(index) does NOT match with annotation. Drawing bounds: \(drawing.path.bounds), Annotation bounds: \(annotationBounds)")
                    }
                    
                    return intersects
                }

                // 찾은 인덱스를 사용하여 드로잉을 제거
                for index in indicesToRemove.reversed() { // 배열에서 삭제할 때는 뒤에서부터 삭제
                    drawingDataArray.remove(at: index)
                    print("Removed drawing at index: \(index), total drawings now: \(drawingDataArray.count)")
                }

                // 주석 삭제
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
            // 각 드로잉의 pageIndex를 사용하여 해당 페이지를 가져옵니다.
            guard let page = document.page(at: drawing.pageIndex) else { continue }
            
            // 드로잉 데이터에 맞는 주석 생성 및 페이지에 추가
            let annotation = createFinalAnnotation(path: drawing.path, page: page)
            annotation.color = drawing.color
            page.addAnnotation(annotation)
        }
        
        pdfView.setNeedsDisplay()
    }
    
}
