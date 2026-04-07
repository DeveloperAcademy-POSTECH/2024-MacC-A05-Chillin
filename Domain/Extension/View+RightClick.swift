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
        onRightClick: @escaping (CGRect) -> Void,
        onLongPress: @escaping (CGRect) -> Void,
        onPressing: @escaping (Bool) -> Void
    ) -> some View {
        self.background(
            MouseClickView(
                onTap: onTap,
                onRightClick: onRightClick,
                onLongPress: onLongPress,
                onPressing: onPressing
            )
        )
    }
}

class TouchHandlingView: UIView {
    var onPressing: ((Bool) -> Void)?
    
    private var workItem: DispatchWorkItem?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let task = DispatchWorkItem { [weak self] in
            self?.onPressing?(true)
        }
        self.workItem = task
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: task)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        cancelAnimation()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        cancelAnimation()
    }
    
    private func cancelAnimation() {
        if let item = workItem, !item.isCancelled {
            item.cancel()
        }
        workItem = nil
        
        onPressing?(false)
    }
}

struct MouseClickView: UIViewRepresentable {
    typealias UIViewType = TouchHandlingView
    
    var onTap: () -> Void
    var onRightClick: (CGRect) -> Void
    var onLongPress: (CGRect) -> Void
    var onPressing: (Bool) -> Void
    
    func makeUIView(context: Context) -> TouchHandlingView {
        let view = TouchHandlingView()
        view.backgroundColor = .clear
        
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = context.coordinator
        
        let rightClick = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRightClick(_:)))
        rightClick.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        rightClick.buttonMaskRequired = .secondary
        rightClick.cancelsTouchesInView = false
        rightClick.delegate = context.coordinator
        
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.cancelsTouchesInView = false
        longPress.delegate = context.coordinator
        
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(rightClick)
        view.addGestureRecognizer(longPress)
        
        return view
    }
    
    func updateUIView(_ uiView: TouchHandlingView, context: Context) {
        uiView.onPressing = onPressing
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: MouseClickView
        
        init(_ parent: MouseClickView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            parent.onTap()
        }
        
        @objc func handleRightClick(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            let globalFrame = view.convert(view.bounds, to: nil)
            parent.onRightClick(globalFrame)
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let view = gesture.view else { return }
            if gesture.state == .began {
                let globalFrame = view.convert(view.bounds, to: nil)
                parent.onLongPress(globalFrame)
                parent.onPressing(false)
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
