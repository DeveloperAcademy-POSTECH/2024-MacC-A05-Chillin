//
//  PDFPage+Selection.swift
//  Reazy
//
//  Created by Minjung Lee on 10/30/24.
//

import UIKit
import PDFKit

extension PDFPage {
    func annotationWithHitTest(at: CGPoint) -> PDFAnnotation? {
        for annotation in annotations {
                if annotation.contains(point: at) {
                return annotation
            }
        }
        return nil
    }
}
