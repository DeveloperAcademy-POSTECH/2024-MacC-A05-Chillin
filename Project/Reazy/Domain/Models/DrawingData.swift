//
//  DrawingData.swift
//  Reazy
//
//  Created by Minjung Lee on 11/5/24.
//

import UIKit

struct Drawing {
    let id: UUID // 드로잉 고유 ID
    var pageIndex: Int // 페이지
    var path: UIBezierPath // 이동 경로
    var color: UIColor // 색상
}
