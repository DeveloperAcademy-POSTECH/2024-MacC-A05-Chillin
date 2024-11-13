//
//  DrawingAnnotation.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import UIKit
import PDFKit

class DrawingAnnotation: PDFAnnotation {
    public var path = UIBezierPath()
    public var uuid: UUID // 고유 ID 추가
    
    init(bounds: CGRect, forType type: PDFAnnotationSubtype, withProperties properties: [String: Any]? = nil) {
        self.uuid = UUID() // 고유 ID 생성
        super.init(bounds: bounds, forType: type, withProperties: properties)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 펜슬이 지나간 자리 그리기
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        let pathCopy = path.copy() as! UIBezierPath
        UIGraphicsPushContext(context)
        context.saveGState()
        
        context.setShouldAntialias(true)
        
        color.set()
        pathCopy.lineJoinStyle = .round
        pathCopy.lineCapStyle = .round
        pathCopy.lineWidth = border?.lineWidth ?? 1.0
        pathCopy.stroke()
        
        context.restoreGState()
        UIGraphicsPopContext()
    }
}

extension PDFAnnotation {
    func contains(point: CGPoint) -> Bool {
        var hitPath: CGPath?
        
        if let path = paths?.first {
            // 얼마나 가까이 닿아야 닿았다고 인식할 건지
            hitPath = path.cgPath.copy(strokingWithWidth: 1.0, lineCap: .round, lineJoin: .round, miterLimit: 0)
        }
        
        return hitPath?.contains(point) ?? false
    }
}
