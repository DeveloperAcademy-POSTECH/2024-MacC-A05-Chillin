//
//  DrawingDataService.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation
import CoreData
import UIKit

class DrawingDataService: DrawingDataInterface {
    private let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Reazy")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func loadDrawingData(for pdfID: UUID) -> Result<[Drawing], Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<DrawingData> = DrawingData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@", pdfID as CVarArg)
        
        do {
            let fetchedDrawings = try dataContext.fetch(fetchRequest)
            let drawings = fetchedDrawings.compactMap { drawingData -> Drawing in
                
                let path: UIBezierPath = {
                    if let pathData = drawingData.path,
                       let unarchivedPath = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: pathData) {
                        return unarchivedPath
                    }
                    return UIBezierPath()
                }()
                
                let color: UIColor = {
                    if let colorData = drawingData.color,
                       let unarchivedColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                        return unarchivedColor
                    }
                    return .primary1
                }()
                
                return Drawing(
                    id: drawingData.id ?? UUID(),
                    pageIndex: Int(drawingData.pageIndex),
                    path: path,
                    color: color
                )
            }
            return .success(drawings)
        } catch {
            return .failure(error)
        }
    }
    
    func saveDrawingData(for pdfID: UUID, with drawing: Drawing) -> Result<VoidResponse, Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@", pdfID as CVarArg)
        
        do {
            if let paperData = try dataContext.fetch(fetchRequest).first {
                
                let newDrawingData = DrawingData(context: dataContext)
                
                newDrawingData.id = drawing.id
                newDrawingData.pageIndex = Int32(drawing.pageIndex)
                
                if let path = try? NSKeyedArchiver.archivedData(withRootObject: drawing.path, requiringSecureCoding: false) {
                    newDrawingData.path = path
                }
                
                if let color = try? NSKeyedArchiver.archivedData(withRootObject: drawing.color, requiringSecureCoding: false) {
                    newDrawingData.color = color
                }
                
                newDrawingData.paperData = paperData
                
                do {
                    try dataContext.save()
                    return .success(VoidResponse())
                } catch {
                    return .failure(error)
                }
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "PaperData not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func deleteDrawingData(for pdfID: UUID, id: UUID) -> Result<VoidResponse, Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<DrawingData> = DrawingData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let drawingToDelete = result.first {
                dataContext.delete(drawingToDelete)
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Drawing not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
}
