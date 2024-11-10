//
//  CommentDataService.swift
//  Reazy
//
//  Created by 유지수 on 11/7/24.
//

import Foundation
import CoreData
import PDFKit
import UIKit

class CommentDataService: CommentDataInterface {
    static let shared = CommentDataService()
    
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    private init() { }
    
    func loadCommentData(for pdfID: UUID, pdfURL: Data) -> Result<[Comment], Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<CommentData> = CommentData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@", pdfID as CVarArg)
        
        do {
            let fetchComments = try dataContext.fetch(fetchRequest)
            let comments = fetchComments.compactMap { commentData -> Comment in
                
                var isStale = false
                var document: PDFDocument?
                var selection: PDFSelection?
                
                if let url = try? URL.init(resolvingBookmarkData: pdfURL, bookmarkDataIsStale: &isStale),
                url.startAccessingSecurityScopedResource() {
                    document = PDFDocument(url: url)
                    url.stopAccessingSecurityScopedResource()
                } else {
                    document = PDFDocument(url: Bundle.main.url(forResource: "Reazy Sample", withExtension: "pdf")!)
                }
                
                if let document = document {
                    let pageIndex = Int(commentData.pageIndex)
                    let firstPage = document.page(at: pageIndex)
                    print("commentData.pageIndex = \(commentData.pageIndex)")
                    print("commentData.text = \(String(describing: commentData.text))")
                    
                    selection = firstPage?.selection(for: NSRange(location: Int(commentData.startIndex), length: Int(commentData.length)))
                }
                
                let selectedLine: CGRect = {
                    if let rectData = commentData.selectedLine,
                       let unarchiveValue = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: rectData) {
                        return unarchiveValue.cgRectValue
                    }
                    return .zero
                }()
                
                return Comment(
                    id: commentData.id ?? UUID(),
                    buttonID: commentData.buttonID,
                    selection: selection ?? PDFSelection(),
                    text: commentData.text ?? "",
                    selectedLine: selectedLine
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
                
                let newComment = CommentData(context: dataContext)
                
                newComment.id = comment.id
                newComment.buttonID = comment.buttonID
                print("comment.pageIndex = \(String(describing: comment.selection.pages.first?.index))")
                print("comment.buttonID = \(comment.buttonID)")
                
                if let firstPage = comment.selection.pages.first,
                   let document = firstPage.document {
                    let pageIndex = document.index(for: firstPage)
                    newComment.pageIndex = Int32(pageIndex)
                    
                    let range = comment.selection.range(at: 0, on: firstPage)
                    newComment.startIndex = Int32(range.location)
                    newComment.length = Int32(range.length)
                }
                
                newComment.text = comment.text
                
                if let selectedLine = try? NSKeyedArchiver.archivedData(withRootObject: NSValue(cgRect: comment.selectedLine), requiringSecureCoding: false) {
                    newComment.selectedLine = selectedLine
                }
                
                newComment.paperData = paperData
                
                do {
                    try dataContext.save()
                    return .success(VoidResponse())
                } catch {
                    return .failure(error)
                }
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
                
                if let firstPage = comment.selection.pages.first,
                   let document = firstPage.document {
                    let pageIndex = document.index(for: firstPage)
                    commentToEdit.pageIndex = Int32(pageIndex)
                    
                    let range = comment.selection.range(at: 0, on: firstPage)
                    commentToEdit.startIndex = Int32(range.location)
                    commentToEdit.length = Int32(range.length)
                }
                
                commentToEdit.text = comment.text
                
                if let selectedLine = try? NSKeyedArchiver.archivedData(withRootObject: NSValue(cgRect: comment.selectedLine), requiringSecureCoding: false) {
                    commentToEdit.selectedLine = selectedLine
                }
                
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
}
