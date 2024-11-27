//
//  PaperDataRepositoryImpl.swift
//  Reazy
//
//  Created by 유지수 on 11/6/24.
//

import Foundation
import CoreData
import SwiftUI
import UIKit

class PaperDataRepositoryImpl: PaperDataRepository {
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    // 저장된 PDF 정보를 모두 불러옵니다
    func loadPDFInfo() -> Result<[PaperInfo], any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        
        do {
            let fetchedDataList = try dataContext.fetch(fetchRequest)
            let pdfDataList = fetchedDataList.map { paperData -> PaperInfo in
                
                return PaperInfo(
                    id: paperData.id,
                    title: paperData.title,
                    thumbnail: paperData.thumbnail,
                    url: paperData.url,
                    focusURL: paperData.focusURL,
                    lastModifiedDate: paperData.lastModifiedDate,
                    isFavorite: paperData.isFavorite,
                    memo: paperData.memo ?? nil,
                    isFigureSaved: paperData.isFigureSaved,
                    folderID: paperData.folderID ?? nil
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
        newPaperData.focusURL = info.focusURL
        newPaperData.thumbnail = info.thumbnail
        newPaperData.lastModifiedDate = info.lastModifiedDate
        newPaperData.isFavorite = info.isFavorite
        newPaperData.memo = info.memo
        newPaperData.isFigureSaved = info.isFigureSaved
        newPaperData.folderID = info.folderID
        
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
        
        var isStale = false
        
        do {
            let results = try dataContext.fetch(fetchRequest)
            if let dataToEdit = results.first {
                if info.title != dataToEdit.title {
                    if let url = try? URL.init(resolvingBookmarkData: info.url, bookmarkDataIsStale: &isStale) {
                        // 실제 파일 이름 변경
                        if !FileManager.default.renameFile(fileURL: url, to: info.title) {
                            print("Failed to rename file")
                            return .failure(PDFUploadError.fileNameDuplication)
                        }
                    }
                }
                
                // 기존 데이터 수정
                dataToEdit.title = info.title
                dataToEdit.url = info.url
                dataToEdit.focusURL = info.focusURL
                dataToEdit.lastModifiedDate = info.lastModifiedDate
                dataToEdit.isFavorite = info.isFavorite
                dataToEdit.memo = info.memo
                dataToEdit.isFigureSaved = info.isFigureSaved
                dataToEdit.folderID = info.folderID
                
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
        
        var isStaleOriginal = false
        var isStaleConcentrate = false
        
        do {
            let results = try dataContext.fetch(fetchRequest)
            
            if let dataToDelete = results.first {
                // 실제 파일 삭제
                if let url = try? URL.init(resolvingBookmarkData: dataToDelete.url, bookmarkDataIsStale: &isStaleOriginal),
                   let _ = try? Data(contentsOf: url) {
                    try FileManager.default.removeItem(at: url)
                }
                
                if let focusURL = dataToDelete.focusURL,
                   let url = try? URL.init(resolvingBookmarkData: focusURL, bookmarkDataIsStale: &isStaleConcentrate),
                   let _ = try? Data(contentsOf: url) {
                    try FileManager.default.removeItem(at: url)
                }
                
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
