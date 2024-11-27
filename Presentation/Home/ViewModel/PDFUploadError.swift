//
//  PDFUploadError.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation


enum PDFUploadError: Error {
    case failedToAccessingSecurityScope
    case fileNameDuplication
}
