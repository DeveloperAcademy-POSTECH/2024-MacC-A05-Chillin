//
//  CanvasView.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var isPencilMode: Bool
    @Binding var color: Color
    let image = UIImage(named: "background") // 서브 뷰로 사용
    
//    var ink: PKInkingTool = PKInkingTool(.pencil, color: .orange, width: 30)
    
    var ink: PKInkingTool {
        PKInkingTool(.pencil, color: UIColor(color), width: 40)
    }
    var eraser: PKEraserTool = PKEraserTool(.bitmap, width: 40)
    
    func makeUIView(context: Context) -> PKCanvasView {
        // 손가락, 펜슬 중 어떤걸로 그릴지
        canvas.drawingPolicy = .pencilOnly
       // 도구를 어느거랑 연결할지
        canvas.tool = isPencilMode ? ink : eraser
        
        canvas.backgroundColor = .clear
        let uiImage: UIImageView = UIImageView(image: image)
        canvas.addSubview(uiImage)
        canvas.sendSubviewToBack(uiImage)
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 버튼 토글 시 bool 값 인식
        uiView.tool = isPencilMode ? ink : eraser
    }
}
