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
    private let pdfID: UUID
    
    weak var pdfView: PDFView!
    private var path: UIBezierPath?
    private var currentAnnotation: DrawingAnnotation?
    private var currentPage: PDFPage?
    var color = UIColor(hex: "#5F5CAB")
    var drawingTool = DrawingTool.none
    private var eraserLayer: CAShapeLayer? = nil
    private var drawingDataArray: [Drawing] = []
    private var drawingService: DrawingDataService
    
    // MARK: - [Lucid] 하이라이트 배열 선언
    @Published var highlightDataArray: [Highlight] = []
    var viewModel: MainPDFViewModel

    
    init(
        viewModel: MainPDFViewModel,
        drawingService: DrawingDataService,
        pdfID: UUID
    ) {
        self.viewModel = viewModel
        self.drawingService = drawingService
        self.pdfID = pdfID
        
        // MARK: - 기존에 저장된 데이터가 있다면 모델에 저장된 데이터를 추가
        switch drawingService.loadDrawingData(for: pdfID) {
        case .success(let drawingList):
            drawingDataArray = drawingList
        case .failure(_):
            return
        }
    }
    
    private func saveAndAddnnotation(_ path: UIBezierPath, on page: PDFPage) {
        let finalAnnotation = createFinalAnnotation(path: path, page: page)
        page.addAnnotation(finalAnnotation)
        
        if let pageIndex = pdfView.document?.index(for: page) {
            let drawingData = Drawing(id: UUID(), pageIndex: pageIndex, path: path, color: color)
            _ = drawingService.saveDrawingData(for: pdfID, with: drawingData)
            drawingDataArray.append(drawingData)
        }
    }
}

extension PDFDrawer: DrawingGestureRecognizerDelegate {
    // 모든 드로잉 꺼내서 pdfview에 페이지 별로 추가하는 함수
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
    
    // 제스처 최초 시작 시 한 번 실행되는 함수
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
    
    // 제스처 움직이는 동안 실행되는 함수
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
    
    // 패드에서 제스처 뗄 때 실행되는 함수
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
    
    // 획을 그리고 배열에 저장하는 함수
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
                _ = drawingService.saveDrawingData(for: pdfID, with: drawingData)
                drawingDataArray.append(drawingData)
            }
        }
        
        return annotation
    }
    

    // MARK: - [Lucid] 하이라이트 기능
    func highlightingText(color: HighlightColors) {

        // toolMode가 highlight일때 동작
        guard viewModel.toolMode == .highlight else { return }
        
        print("\n\n < - - - - - - - - - - | NewDrag | - - - - - - - - - - >\n")

        // PDFView 안에서 스크롤 영역 파악
        guard let currentSelection = pdfView.currentSelection else { return }
        print("1. 드래그 텍스트 : \(currentSelection)")

        // 선택된 텍스트를 줄 단위로 나눔
        let selections = currentSelection.selectionsByLine()
        print("2. 줄단위 텍스트 : \(selections)")

        guard let page = selections.first?.pages.first else { return }
        print("3. 해당 페이지 : \(page)")

        let highlightColor = color.uiColor
        print("4. 하이라이트 색상 : \(highlightColor) \n")
        
        var loopCheckNum = 0

        selections.forEach { selection in
            
            loopCheckNum += 1
            
            var bounds = selection.bounds(for: page)
            print("5. 텍스트 영역 좌표 : \(bounds)")
            
            let originBoundsHeight = bounds.size.height
            bounds.size.height *= 0.6                                                   // bounds 높이 조정하기
            bounds.origin.y += (originBoundsHeight - bounds.size.height) / 2            // 줄인 높인만큼 y축 이동

            let highlight = PDFAnnotation(bounds: bounds, forType: .highlight, withProperties: nil)
            highlight.endLineStyle = .none
            highlight.color = highlightColor

            page.addAnnotation(highlight)
            
            // MARK: - [Lucid] 하이라이트 배열 추가
            let highlightData = Highlight(id: UUID(), pageIndex: page, bounds: bounds, color: highlight.color)
            highlightDataArray.append(highlightData)
            print("6-\(loopCheckNum). 하이라이트 데이터 : \(highlightData) \n")
        }
        
        print("[추가] 하이라이트 데이터 배열 : \(highlightDataArray.count)")
        pdfView.clearSelection()
    }
    
    
    // 지우개로 주석 지울 때 실행되는 함수
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
                
                // 뒤쪽 인덱스 주석부터 제거
                for index in indicesToRemove.reversed() {
                    let drawing = drawingDataArray[index]
                    let id = drawing.id
                    
                    _ = drawingService.deleteDrawingData(for: pdfID, id: id)
                    drawingDataArray.remove(at: index)
                }
                
                // MARK: - [Lucid] 하이라이트 배열 삭제
                let highlightToRemove = highlightDataArray.indices.filter { index in
                    let highlight = highlightDataArray[index]
                    return highlight.pageIndex == page && highlight.bounds.intersects(annotationBounds)
                }
                
                for index in highlightToRemove.reversed() {
                    highlightDataArray.remove(at: index)
                }
                
                print("\n\n < - - - - - - - - - - | NewDrag | - - - - - - - - - - >\n")
                print("[삭제] 하이라이트 데이터 배열 : \(highlightDataArray.count)")
                
                page.removeAnnotation(annotation)
            }
        }
    }
    
    private func forceRedraw(annotation: PDFAnnotation, onPage: PDFPage) {
        onPage.removeAnnotation(annotation)
        onPage.addAnnotation(annotation)
    }
}
