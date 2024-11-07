//
//  PaperDataService.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation
import CoreData
import UIKit

class PaperDataService: PaperDataInterface {
    private let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "Reazy")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    // 저장된 PDF 정보를 모두 불러옵니다
    func loadPDFInfo() -> Result<[PaperInfo], any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        
        do {
            let fetchedDataList = try dataContext.fetch(fetchRequest)
            let pdfDataList = fetchedDataList.map { paperData -> PaperInfo in
                // TODO: - URL 타입 수정
                
                return PaperInfo(
                    id: paperData.id,
                    title: paperData.title,
                    datetime: paperData.dateTime ?? "--",
                    author: paperData.author ?? "--",
                    pages: Int(paperData.pages),
                    publisher: paperData.publisher ?? "--",
                    thumbnail: paperData.thumbnail,
                    url: paperData.url,
                    lastModifiedDate: paperData.lastModifiedDate,
                    isFavorite: paperData.isFavorite
                )
            }
            return .success(pdfDataList)
        } catch {
            return .failure(error)
        }
    }
    
    // 새로운 PDF를 저장합니다
    func savePDFInfo(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let newPaperData = PaperData(context: dataContext)
        
        newPaperData.id = info.id
        newPaperData.title = info.title
        newPaperData.dateTime = info.dateTime
        newPaperData.author = info.author
        newPaperData.url = info.url
        newPaperData.pages = Int32(info.pages)
        newPaperData.publisher = info.publisher
        newPaperData.thumbnail = info.thumbnail
        newPaperData.lastModifiedDate = info.lastModifiedDate
        newPaperData.isFavorite = info.isFavorite
        
        do {
            try dataContext.save()
            return .success(VoidResponse())
        } catch {
            return .failure(error)
        }
    }
    
    // 기존 PDF 정보를 수정합니다
    func editPDFInfo(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", info.id as CVarArg)
        
        do {
            let results = try dataContext.fetch(fetchRequest)
            if let dataToEdit = results.first {
                // 기존 데이터 수정
                dataToEdit.title = info.title
                dataToEdit.dateTime = info.dateTime
                dataToEdit.author = info.author
                dataToEdit.url = info.url
                dataToEdit.pages = Int32(info.pages)
                dataToEdit.publisher = info.publisher
                dataToEdit.lastModifiedDate = info.lastModifiedDate
                dataToEdit.isFavorite = info.isFavorite
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    // PDF 정보를 삭제합니다
    func deletePDFInfo(id: UUID) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try dataContext.fetch(fetchRequest)
            if let dataToDelete = results.first {
                dataContext.delete(dataToDelete)
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
