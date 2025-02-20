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
        
        do {
            let fetchedDataList = try dataContext.fetch(fetchRequest)
            let folderList = fetchedDataList.map { folderData -> Folder in
                
                return Folder(
                    id: folderData.id,
                    title: folderData.title,
                    createdAt: folderData.createdAt,
                    color: folderData.color,
                    parentFolderID: folderData.parentFolderID ?? nil
                )
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
            folderData.color = folder.color
            folderData.parentFolderID = folder.parentFolderID
            
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
            folderData.color = folder.color
            folderData.parentFolderID = folder.parentFolderID
            
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
