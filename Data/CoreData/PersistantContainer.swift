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

    private let _container: NSPersistentCloudKitContainer

    private init() {
        self._container = .init(name: "Reazy")

        let description = _container.persistentStoreDescriptions.first

        // 자동 마이그레이션 설정
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        // CloudKit 동기화에 필요한 Persistent History Tracking
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // CloudKit 컨테이너 연결
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.chillin.reazy"
        )

        self._container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // CloudKit 백그라운드 동기화 결과를 viewContext에 자동 반영
        self._container.viewContext.automaticallyMergesChangesFromParent = true
        self._container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    public func resetContainer() {
        let coordinator = self._container.persistentStoreCoordinator
        
        for store in coordinator.persistentStores {
            do {
                if let storeURL = store.url {
                    try coordinator.destroyPersistentStore(at: storeURL, ofType: store.type, options: nil)
                }
            } catch {
                log("Failed to reset Core Data: \(error.localizedDescription)")
            }
        }
        
        self._container.loadPersistentStores {
            (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
