//
//  PersistantContainer.swift
//  Reazy
//
//  Created by 문인범 on 11/10/24.
//

import CoreData


final class PersistantContainer {
    static let shared = PersistantContainer()
    
    public var container: NSPersistentContainer {
        self._container
    }
    
    private let _container: NSPersistentContainer
    
    private init() {
        self._container = .init(name: "Reazy")
        
        // 자동 마이그레이션 설정
        let description = _container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        self._container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    public func resetContainer() {
        let coordinator = self._container.persistentStoreCoordinator
        
        for store in coordinator.persistentStores {
            do {
                if let storeURL = store.url {
                    try coordinator.destroyPersistentStore(at: storeURL, ofType: store.type, options: nil)
                }
            } catch {
                print("Failed to reset Core Data: \(error.localizedDescription)")
            }
        }
        
        self._container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    private func performMigrationIfNeeded() {
        let context = _container.viewContext
//        let request: NSFetchRequest<PaperTag> = PaperTag.fetchRequest()
    }
}
