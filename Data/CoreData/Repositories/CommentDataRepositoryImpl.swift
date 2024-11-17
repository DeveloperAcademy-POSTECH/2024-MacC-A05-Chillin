//
//  CommentDataService.swift
//  Reazy
//
//  Created by 유지수 on 11/11/24.
//

import Foundation
import CoreData
import UIKit

class CommentDataRepositoryImpl: CommentDataRepository {
    static let shared = CommentDataRepositoryImpl()
    
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    private init() { }
    
    func loadCommentData(for pdfID: UUID) -> Result<[Comment], Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<CommentData> = CommentData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@", pdfID as CVarArg)
        
        do {
            let fetchedComments = try dataContext.fetch(fetchRequest)
            let comments = fetchedComments.map { commentData -> Comment in
                
                let selectionsByLine = commentData.selectionByLine.map { selection in
                    let bounds = convertDataToCGRect(selection.bounds)
                    
                    return selectionByLine(page: Int(selection.page), bounds: bounds)
                }
                
                let bounds = convertDataToCGRect(commentData.bounds)
                
                return Comment(
                    id: commentData.id,
                    buttonId: commentData.buttonID,
                    text: commentData.text,
                    selectedText: commentData.selectedText,
                    selectionsByLine: selectionsByLine,
                    pages: commentData.pages,
                    bounds: bounds
                )
            }
            return .success(comments)
        } catch {
            return .failure(error)
        }
    }
    
    func saveCommentData(for pdfID: UUID, with comment: Comment) -> Result<VoidResponse, Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", pdfID as CVarArg)
        
        do {
            if let paperData = try dataContext.fetch(fetchRequest).first {
                let newCommentData = CommentData(context: dataContext)
                
                newCommentData.id = comment.id
                newCommentData.buttonID = comment.buttonId
                newCommentData.text = comment.text
                newCommentData.selectedText = comment.selectedText
                
                newCommentData.selectionByLine = Set(comment.selectionsByLine.map { selection in
                    let selectionData = SelectionByLine(context: dataContext)
                    selectionData.page = Int32(selection.page)
                    
                    let bounds = convertCGRectToData(selection.bounds) ?? Data()
                    selectionData.bounds = bounds
                    return selectionData
                })
                
                newCommentData.pages = comment.pages
                
                newCommentData.bounds = convertCGRectToData(comment.bounds) ?? Data()
                
                newCommentData.paperData = paperData
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "CommentData not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func editCommentData(for pdfID: UUID, with comment: Comment) -> Result<VoidResponse, Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<CommentData> = CommentData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, comment.id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let commentToEdit = result.first {
                
                commentToEdit.text = comment.text
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Comment not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func deleteCommentData(for pdfID: UUID, id: UUID) -> Result<VoidResponse, Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<CommentData> = CommentData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let commentToDelete = result.first {
                
                dataContext.delete(commentToDelete)
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Comment not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    private func convertCGRectToData(_ rect: CGRect) -> Data? {
        return try? NSKeyedArchiver.archivedData(withRootObject: NSValue(cgRect: rect), requiringSecureCoding: true)
    }
    
    private func convertDataToCGRect(_ data: Data?) -> CGRect {
        guard let data = data,
              let rectValue = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: data) else {
            return .zero
        }
        return rectValue.cgRectValue
    }
}
