//
//  PaperDataService.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation
import CoreData
import UIKit

class PaperDataRepositoryImpl: PaperDataRepository {
//    static let shared = PaperDataRepositoryImpl()
    
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
//    private init() { }
    
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
                    thumbnail: paperData.thumbnail,
                    url: paperData.url,
                    lastModifiedDate: paperData.lastModifiedDate,
                    isFavorite: paperData.isFavorite,
                    memo: paperData.memo ?? nil,
                    isFigureSaved: paperData.isFigureSaved
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
        newPaperData.url = info.url
        newPaperData.thumbnail = info.thumbnail
        newPaperData.lastModifiedDate = info.lastModifiedDate
        newPaperData.isFavorite = info.isFavorite
        newPaperData.memo = info.memo
        newPaperData.isFigureSaved = info.isFigureSaved
        
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
