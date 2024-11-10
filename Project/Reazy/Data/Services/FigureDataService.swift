//
//  FigureDataService.swift
//  Reazy
//
//  Created by 유지수 on 11/10/24.
//

import Foundation
import CoreData
import UIKit

class FigureDataService: FigureDataInterface {
    static let shared = FigureDataService()
    
    private let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "Reazy")
        container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func loadFigureData(for pdfID: UUID) -> Result<[Figure], any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<FigureData> = FigureData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@", pdfID as CVarArg)
        
        do {
            let fetchedFigures = try dataContext.fetch(fetchRequest)
            let figures = fetchedFigures.map { figureData -> Figure in
                
                return Figure(
                    id: figureData.id,
                    head: figureData.head,
                    label: figureData.label,
                    figDesc: figureData.figDesc,
                    coords: figureData.coords,
                    graphicCoord: figureData.graphiCoord
                )
            }
            return .success(figures)
        } catch {
            return .failure(error)
        }
    }
    
    func saveFigureData(for pdfID: UUID, with figure: Figure) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", pdfID as CVarArg)
        
        do {
            if let paperData = try dataContext.fetch(fetchRequest).first {
                
                let newFigureData = FigureData(context: dataContext)
                
                newFigureData.id = figure.id
                newFigureData.head = figure.head
                newFigureData.label = figure.label
                newFigureData.figDesc = figure.figDesc
                newFigureData.coords = figure.coords
                newFigureData.graphiCoord = figure.graphicCoord
                
                newFigureData.paperData = paperData
                
                do {
                    try dataContext.save()
                    return .success(VoidResponse())
                } catch {
                    return .failure(error)
                }
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "FigureData not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func editFigureData(for pdfID: UUID, with figure: Figure) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<FigureData> = FigureData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, figure.id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let figureToEdit = result.first {
                
                figureToEdit.head = figure.head
                figureToEdit.label = figure.label
                figureToEdit.figDesc = figure.figDesc
                figureToEdit.coords = figure.coords
                figureToEdit.graphiCoord = figure.graphicCoord
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Figure not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func deleteFigureData(for pdfID: UUID, id: String) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<FigureData> = FigureData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let figureToDelete = result.first {
                dataContext.delete(figureToDelete)
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Figure not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
}
