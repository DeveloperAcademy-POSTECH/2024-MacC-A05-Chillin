//
//  NetworkManager.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import Foundation

// MARK: - 네트워크 요청 관련 클래스
class NetworkManager {
    
}


// MARK: - 네트워크 에러
enum NetworkManagerError: Error {
    case invalidInfo    // info.plist 오류
    case invalidURL     // url 생성 오류
    case invalidPDF     // pdf 없음 오류
    case badRequest     // 200~299 번대가 아닐 시
    case corruptedPDF   // 500번일 때(PDF OCR 미적용)
}
