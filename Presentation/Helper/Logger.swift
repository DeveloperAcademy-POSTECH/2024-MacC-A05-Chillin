//
//  Logger.swift
//  Reazy
//
//  Created by 문인범 on 12/1/25.
//

import Foundation

/**
 기존 print 메소드에서 호출된 파일, 라인, 메소드명이 추가되어 출력됩니다.
 */
public func log(
    _ message: @autoclosure () -> Any,
    fileName: String = #fileID,
    line: Int = #line,
    function: String = #function ) {
        print("""
            \(Date()) \(fileName), line: \(line)
            \(function)
            \(message())
            """)
}
