//
//  CollectionDataRepositoryImpl.swift
//  Reazy
//
//  Created by 유지수 on 11/27/24.
//

import Foundation
import CoreData

class CollectionDataRepositoryImpl: CollectionDataRepository {
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    func loadCollectionData(for pdfID: UUID) -> Result<[Collection], any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<CollectionData> = CollectionData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@", pdfID as CVarArg)
        
        do {
            let fetchedCollections = try dataContext.fetch(fetchRequest)
            let collections = fetchedCollections.map { collectionData -> Collection in
                
                return Collection(
                    id: collectionData.id,
                    head: collectionData.head,
                    label: collectionData.label,
                    figDesc: collectionData.figDesc,
                    coords: collectionData.coords,
                    graphicCoord: collectionData.graphicCoord
                )
            }
            return .success(collections)
        } catch {
            return .failure(error)
        }
    }
    
    func saveCollectionData(for pdfID: UUID, with collection: Collection) -> Result<VoidResponse, any Error> {
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
                    
                    let newCollectionData = CollectionData(context: context)
                    
                    newCollectionData.id = collection.id
                    newCollectionData.head = collection.head
                    newCollectionData.label = collection.label
                    newCollectionData.figDesc = collection.figDesc
                    newCollectionData.coords = collection.coords
                    newCollectionData.graphicCoord = collection.graphicCoord
                    
                    newCollectionData.paperData = paperData
                    
                    do {
                        try context.save()
                        result = .success(.init())
                    } catch {
                        print(String(describing: error))
                        result = .failure(error)
                    }
                } else {
                    result = .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "CollectionData not found"]))
                }
            } catch {
                result = .failure(error)
            }
        }
        
        if result == nil {
            return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "CollectionData not found"]))
        }
        
        return result!
    }
    
    func editFigureData(for pdfID: UUID, with collection: Collection) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<CollectionData> = CollectionData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, collection.id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let collectionToEdit = result.first {
                
                collectionToEdit.head = collection.head
                collectionToEdit.label = collection.label
                collectionToEdit.figDesc = collection.figDesc
                collectionToEdit.coords = collection.coords
                collectionToEdit.graphicCoord = collection.graphicCoord
                
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Collection not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
    
    func deleteCollectionData(for pdfID: UUID, id: String) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<CollectionData> = CollectionData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "paperData.id == %@ AND id == %@", pdfID as CVarArg, id as CVarArg)
        
        do {
            let result = try dataContext.fetch(fetchRequest)
            if let collectionToDelete = result.first {
                dataContext.delete(collectionToDelete)
                try dataContext.save()
                return .success(VoidResponse())
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Collection not found"]))
            }
        } catch {
            return .failure(error)
        }
    }
}
