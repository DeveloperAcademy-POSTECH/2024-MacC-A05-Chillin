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
    
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    private init() { }
    
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
                    graphicCoord: figureData.graphicCoord
                )
            }
            return .success(figures)
        } catch {
            return .failure(error)
        }
    }
    
    func saveFigureData(for pdfID: UUID, with figure: Figure) -> Result<VoidResponse, any Error> {
        var result: Result<VoidResponse, any Error>?
        
        /// NSManagedObject는 Thread-safe 하지 못해 하나의 쓰레드에서만 사용해야 함
        /// 해결 방법으로 performBackgroundTask 사용
        container.performBackgroundTask { context in
            // 저장되어 있는 것을 우선으로 하는 merge policy
            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
            
            let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", pdfID as CVarArg)
            
            do {
                if let paperData = try context.fetch(fetchRequest).first {
                    
                    let newFigureData = FigureData(context: context)
                    
                    newFigureData.id = figure.id
                    newFigureData.head = figure.head
                    newFigureData.label = figure.label
                    newFigureData.figDesc = figure.figDesc
                    newFigureData.coords = figure.coords
                    newFigureData.graphicCoord = figure.graphicCoord
                    
                    newFigureData.paperData = paperData
                    
                    do {
                        try context.save()
                        result = .success(.init())
                    } catch {
                        print(String(describing: error))
                        result = .failure(error)
                    }
                } else {
                    result = .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "FigureData not found"]))
                }
            } catch {
                result = .failure(error)
            }
        }
        
        if result == nil {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "FigureData not found"]))
        }
        
        return result!
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
                figureToEdit.graphicCoord = figure.graphicCoord
                
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
    
    func editPaperInfo(info: PaperInfo) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", info.id as CVarArg)
        
        do {
            let results = try dataContext.fetch(fetchRequest)
            if let dataToEdit = results.first {
                // 기존 데이터 수정
                dataToEdit.title = info.title
                dataToEdit.url = info.url
                dataToEdit.lastModifiedDate = info.lastModifiedDate
                dataToEdit.isFavorite = info.isFavorite
                dataToEdit.memo = info.memo
                dataToEdit.isFigureSaved = info.isFigureSaved
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
}
