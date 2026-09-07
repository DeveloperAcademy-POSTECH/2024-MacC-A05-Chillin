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

    /// 스토어를 여는 데 실패한 경우의 에러. CloudKit 없이 로컬로 여는 데까지 실패하면 값이 남는다.
    /// 설정 화면 등에서 사용자에게 상태를 알리는 용도
    public private(set) var storeLoadFailure: Error?

    /// CloudKit 동기화가 실제로 켜진 채 스토어가 열렸는지. 폴백으로 열린 경우 false
    public private(set) var isCloudKitEnabled = false

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

        var loadError: Error?
        self._container.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            // 여기서 죽으면 사용자는 앱을 실행조차 못 하고, 스스로 복구할 방법도 없다.
            // 실패 원인이 CloudKit 쪽일 수 있으므로 CloudKit 없이 한 번 더 시도해서
            // 최소한 로컬에 있는 기존 데이터는 열어 준다 (데이터를 지우는 처리는 절대 하지 않는다)
            log("CloudKit 스토어 로드 실패, 로컬 전용으로 재시도합니다: \(error)")

            description?.cloudKitContainerOptions = nil

            var fallbackError: Error?
            self._container.loadPersistentStores { _, error in
                fallbackError = error
            }

            if let fallbackError {
                // 이 경우에도 앱을 죽이지 않는다. 데이터 접근은 실패하겠지만,
                // 사용자가 상황을 인지하고 문의할 수 있는 상태로 두는 편이 낫다
                log("로컬 스토어 로드도 실패했습니다: \(fallbackError)")
                self.storeLoadFailure = fallbackError
            }
        } else {
            self.isCloudKitEnabled = true
        }

        // CloudKit 백그라운드 동기화 결과를 viewContext에 자동 반영
        self._container.viewContext.automaticallyMergesChangesFromParent = true
        self._container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
