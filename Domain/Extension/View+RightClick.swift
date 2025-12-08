//
//  View+RightClick.swift
//  Reazy
//
//  Created by 유지수 on 12/8/25.
//

import SwiftUI
import UIKit

extension View {
    func onMouse(
        onTap: @escaping () -> Void,
        onRightClick: @escaping (CGPoint) -> Void
    ) -> some View {
        self.overlay(
            MouseClickView(onTap: onTap, onRightClick: onRightClick)
        )
    }
}

struct MouseClickView: UIViewRepresentable {
    typealias UIViewType = UIView
    
    var onTap: () -> Void
    var onRightClick: (CGPoint) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        let rightClick = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRightClick(_:)))
        rightClick.allowedTouchTypes =  [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        rightClick.buttonMaskRequired = .secondary
        rightClick.delegate = context.coordinator
        
        let leftClick = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLeftClick(_:)))
        leftClick.delegate = context.coordinator
        
        view.addGestureRecognizer(rightClick)
        view.addGestureRecognizer(leftClick)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap, onRightClick: onRightClick)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTap: () -> Void
        var onRightClick: (CGPoint) -> Void
        
        init(onTap: @escaping () -> Void, onRightClick: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
            self.onRightClick = onRightClick
        }
        
        @objc func handleRightClick(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let localPoint = CGPoint(x: view.bounds.midX, y: view.bounds.maxY)
            let globalFixedPoint = view.convert(localPoint, to: nil)
            
            onRightClick(globalFixedPoint)
        }
        
        @objc func handleLeftClick(_ gesture: UITapGestureRecognizer) {
            onTap()
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
