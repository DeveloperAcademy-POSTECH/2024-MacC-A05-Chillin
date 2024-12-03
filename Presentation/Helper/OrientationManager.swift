//
//  OrientationManager.swift
//  Reazy
//
//  Created by 문인범 on 12/1/24.
//

import UIKit
import SwiftUICore
import Combine


class OrientationManager: ObservableObject {
    @Published var type: LayoutOrientation = .horizontal
    
    private var cancellabels: [AnyCancellable] = []
    
    init() {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene as? UIWindowScene else { return }
        
        let orientation = sceneDelegate.interfaceOrientation
        
        switch orientation {
        case .portrait, .portraitUpsideDown:
            self.type = .vertical
        case .landscapeLeft, .landscapeRight:
            self.type = .horizontal
        default:
            break
        }
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                switch UIDevice.current.orientation {
                case .portrait, .portraitUpsideDown:
                    self.type = .vertical
                case .landscapeLeft, .landscapeRight:
                    self.type = .horizontal
                case .faceUp, .faceDown:
                    self.type = self.getOrientationFromFace()
                default:
                    break
                }
            }
            .store(in: &self.cancellabels)
    }
    
    deinit {
        self.cancellabels.forEach { $0.cancel() }
    }
    
    private func getOrientationFromFace() -> LayoutOrientation {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene as? UIWindowScene else { return .horizontal }
        
        switch sceneDelegate.interfaceOrientation {
        case .portrait, .portraitUpsideDown:
            return .vertical
        case .landscapeLeft, .landscapeRight:
            return .horizontal
        default:
            return .horizontal
        }
    }
}

enum LayoutOrientation {
    case vertical, horizontal
}
