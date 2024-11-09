//
//  CommentDataInterface.swift
//  Reazy
//
//  Created by 유지수 on 11/7/24.
//

import Foundation

protocol CommentDataInterface {
    /// 코멘트 기록을 불러옵니다
    func loadCommentData(for pdfID: UUID, pdfURL: Data) -> Result<[Comment], Error>
    /// 코멘트 기록을 저장합니다
    func saveCommentData(for pdfID: UUID, with comment: Comment) -> Result<VoidResponse, Error>
    /// 코멘트 기록을 수정합니다
    func editCommentData(for pdfID: UUID, with comment: Comment) -> Result<VoidResponse, Error>
    /// 코멘트 기록을 삭제합니다
    func deleteCommentData(for pdfID: UUID, id: UUID) -> Result<VoidResponse, Error>
}
