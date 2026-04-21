//
//  DrawingGestureRecognizer.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import UIKit

enum TouchType {
    case direct
    case indirect
    case pencil
}

protocol DrawingGestureRecognizerDelegate: AnyObject {
    func gestureRecognizerBegan(_ location: CGPoint)
    func gestureRecognizerMoved(_ location: CGPoint)
    func gestureRecognizerEnded(_ location: CGPoint)
}

class DrawingGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        self.delegate = self
    }
    weak var drawingDelegate: DrawingGestureRecognizerDelegate?
    var isCaptureMode: Bool = false
    
    // 스무딩용 포인트 버퍼
    private var pointBuffer: [CGPoint] = []
    private let bufferSize = 3 // 값이 클수록 더 부드럽고 느리게 반응, 1~5 권장
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return isCaptureMode
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first,
            let numberOfTouches = event?.allTouches?.count,
            numberOfTouches == 1 {
            state = .began
            
            // 시작 시 버퍼 초기화
            pointBuffer.removeAll()
            
            let location = touch.location(in: self.view)
            drawingDelegate?.gestureRecognizerBegan(location)
        } else {
            state = .failed
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .changed
        
        guard let location = touches.first?.location(in: self.view) else { return }
        
        // 버퍼에 포인트 추가
        pointBuffer.append(location)
        if pointBuffer.count > bufferSize {
            pointBuffer.removeFirst()
        }
        
        // 버퍼 평균값으로 스무딩
        let smoothed = CGPoint(
            x: pointBuffer.map(\.x).reduce(0, +) / CGFloat(pointBuffer.count),
            y: pointBuffer.map(\.y).reduce(0, +) / CGFloat(pointBuffer.count)
        )
        
        drawingDelegate?.gestureRecognizerMoved(smoothed)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self.view) else {
            state = .ended
            return
        }
        
        // 끝날 때 버퍼 초기화
        pointBuffer.removeAll()
        
        drawingDelegate?.gestureRecognizerEnded(location)
        state = .ended
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        pointBuffer.removeAll()
        state = .failed
    }
}
