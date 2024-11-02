//
//  SearchBoxView.swift
//  Reazy
//
//  Created by 문인범 on 10/29/24.
//

import UIKit

/**
 코너를 둥글게 한 삼각형 
 */
final class RoundedCornerTriangle: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let triangle = CAShapeLayer()
        triangle.fillColor = UIColor.gray100.cgColor
        triangle.path = createRoundedTriangle(width: 46, height: 30, radius: 4)
        triangle.position = .init(x: 51, y: 0)
        self.layer.addSublayer(triangle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createRoundedTriangle(width: CGFloat, height: CGFloat, radius: CGFloat) -> CGPath {
        let point1 = CGPoint(x: -width / 2, y: height / 2)
        let point2 = CGPoint(x: 0, y: -height / 2)
        let point3 = CGPoint(x: width / 2, y: height / 2)
        
        let path = CGMutablePath()
        path.move(to: .init(x: 0, y: height / 2))
        path.addArc(tangent1End: point1, tangent2End: point2, radius: radius)
        path.addArc(tangent1End: point2, tangent2End: point3, radius: radius)
        path.addArc(tangent1End: point3, tangent2End: point1, radius: radius)
        path.closeSubpath()
        
        return path
    }
}
