//
//  FolderDataRepositoryImpl.swift
//  Reazy
//
//  Created by 유지수 on 11/19/24.
//

import Foundation
import CoreData
import SwiftUI
import UIKit

class FolderDataRepositoryImpl: FolderDataRepository {
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    func loadFolders() -> Result<[Folder], any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<FolderData> = FolderData.fetchRequest()
        
        var folderCache: [UUID: Folder] = [:]
        
        do {
            let fetchedDataList = try dataContext.fetch(fetchRequest)
            let folderList = fetchedDataList.map { folderData in
                convertToFolder(folderData: folderData, cache: &folderCache)
            }
            return .success(folderList)
        } catch {
            return .failure(error)
        }
    }
    
    func saveFolder(_ folder: Folder) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        
        do {
            let folderData = FolderData(context: dataContext)
            folderData.id = folder.id
            folderData.title = folder.title
            folderData.createdAt = folder.createdAt
            folderData.color = UIColor(folder.color)
            folderData.memo = folder.memo
            folderData.isFavorite = folder.isFavorite
            
            if let parentFolder = folder.parentFolder {
                let fetchRequest: NSFetchRequest<FolderData> = FolderData.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", parentFolder.id as CVarArg)
                
                if let parentFolderData = try dataContext.fetch(fetchRequest).first {
                    if parentFolderData.subFolders == nil {
                        parentFolderData.subFolders = []
                    }
                    
                    parentFolderData.subFolders?.insert(folderData)
                    folderData.parentFolder = parentFolderData
                }
            }
            
            try dataContext.save()
            return .success(VoidResponse())
        } catch {
            return .failure(error)
        }
    }
    
    func editFolder(_ folder: Folder) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<FolderData> = FolderData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", folder.id as CVarArg)
        
        do {
            guard let folderData = try dataContext.fetch(fetchRequest).first else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Folder not found"]))
            }
            
            folderData.title = folder.title
            folderData.color = UIColor(folder.color)
            folderData.memo = folder.memo
            folder.isFavorite = folderData.isFavorite
            
            try dataContext.save()
            return .success(VoidResponse())
        } catch {
            return .failure(error)
        }
    }
    
    func deleteFolder(id: UUID) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<FolderData> = FolderData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try dataContext.fetch(fetchRequest)
            if let folderToDelete = results.first {
                dataContext.delete(folderToDelete)
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Folder not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
}

extension FolderDataRepositoryImpl {
    private func convertToFolder(folderData: FolderData, cache: inout [UUID: Folder]) -> Folder {
        // 이미 변환된 폴더가 있다면 반환
        if let cachedFolder = cache[folderData.id] {
            return cachedFolder
        }
        
        // 상위 폴더 처리
        let parentFolder = folderData.parentFolder.flatMap { parentData in
            convertToFolder(folderData: parentData, cache: &cache)
        }
        
        // 하위 폴더 처리
        let subFolders = convertSubFolders(subFoldersData: folderData.subFolders, cache: &cache)
        
        let documents = convertDocuments(documentsData: folderData.documents)
        
        let folder = Folder(
            id: folderData.id,
            title: folderData.title,
            color: Color(uiColor: folderData.color),
            parentFolder: parentFolder,
            subFolders: subFolders,
            documents: documents
        )
        
        cache[folderData.id] = folder
        return folder
    }
    
    private func convertSubFolders(subFoldersData: Set<FolderData>?, cache: inout [UUID: Folder]) -> [Folder] {
        guard let subFoldersDataSet = subFoldersData else {
            return []
        }
        
        return subFoldersDataSet.map { subFolderData in
            convertToFolder(folderData: subFolderData, cache: &cache)
        }
    }
    
    private func convertDocuments(documentsData: Set<PaperData>?) -> [PaperInfo] {
        guard let documentsDataSet = documentsData else {
            return []
        }
        
        return documentsDataSet.map { paperData in
            PaperInfo(
                id: paperData.id,
                title: paperData.title,
                thumbnail: paperData.thumbnail,
                url: paperData.url,
                lastModifiedDate: paperData.lastModifiedDate,
                isFavorite: paperData.isFavorite,
                memo: paperData.memo,
                isFigureSaved: paperData.isFigureSaved
            )
        }
    }
}

