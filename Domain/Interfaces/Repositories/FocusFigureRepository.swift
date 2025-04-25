//
//  FocusFigureRepository.swift
//  Reazy
//
//  Created by 문인범 on 11/15/24.
//

import Foundation
import Combine
import PDFKit


protocol FocusFigureRepository {
    func fetchFigures(
        url: URL,
        completion: @escaping (Result<PDFLayoutResponseDTO, NetworkManagerError>) -> Void
    ) async
    
    func fetchFocus(
        process: NetworkManager.ServiceName,
        url: URL
    ) async -> Result<PDFLayoutResponseDTO, NetworkManagerError>
}
