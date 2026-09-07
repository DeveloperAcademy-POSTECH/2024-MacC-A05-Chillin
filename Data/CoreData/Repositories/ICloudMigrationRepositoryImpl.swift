//
//  ICloudMigrationRepositoryImpl.swift
//  Reazy
//
//  Created by Claude on 7/19/26.
//

import Foundation
import CoreData

final class ICloudMigrationRepositoryImpl: ICloudMigrationRepository {
    private let container: NSPersistentContainer = PersistantContainer.shared.container

    /// 마이그레이션은 메인 스레드를 벗어난 곳에서 실행되므로(호출부가 @MainActor여도 nonisolated async 함수는
    /// 백그라운드 실행자로 넘어간다) 메인 큐 전용인 viewContext를 쓰면 CoreData 동시성 규칙 위반이다.
    /// 전용 백그라운드 컨텍스트를 만들어 두고 모든 접근을 performAndWait로 감싼다.
    private let context: NSManagedObjectContext

    init() {
        let context = PersistantContainer.shared.container.newBackgroundContext()
        // 마이그레이션 도중 메인 스레드에서 논문이 추가/삭제되면 그 변경을 이어받는다
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.context = context
    }

    func fetchAllPaperLocations() -> Result<[PaperFileLocation], Error> {
        var result: Result<[PaperFileLocation], Error> = .success([])

        context.performAndWait {
            let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()

            do {
                let fetchedDataList = try context.fetch(fetchRequest)
                let locations = fetchedDataList.map { paperData in
                    Self.makeLocation(from: paperData)
                }
                result = .success(locations)
            } catch {
                result = .failure(error)
            }
        }

        return result
    }

    func fetchPaperLocation(id: UUID) -> Result<PaperFileLocation, Error> {
        var result: Result<PaperFileLocation, Error> = .failure(Self.notFoundError)

        context.performAndWait {
            let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            do {
                guard let paperData = try context.fetch(fetchRequest).first else {
                    result = .failure(Self.notFoundError)
                    return
                }
                result = .success(Self.makeLocation(from: paperData))
            } catch {
                result = .failure(error)
            }
        }

        return result
    }

    func updateFileLocation(
        id: UUID,
        url: Data,
        relativePath: String?,
        focusURL: Data?,
        focusRelativePath: String?
    ) -> Result<VoidResponse, Error> {
        var result: Result<VoidResponse, Error> = .failure(Self.notFoundError)

        context.performAndWait {
            let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            do {
                guard let dataToEdit = try context.fetch(fetchRequest).first else {
                    result = .failure(Self.notFoundError)
                    return
                }

                dataToEdit.url = url
                dataToEdit.relativePath = relativePath
                dataToEdit.focusURL = focusURL
                dataToEdit.focusRelativePath = focusRelativePath

                try context.save()
                result = .success(VoidResponse())
            } catch {
                context.rollback()
                result = .failure(error)
            }
        }

        return result
    }

    /// 상대 경로만 갱신한다. 북마크는 손대지 않으므로 기존 경로 해석에 영향이 없다
    func updateRelativePaths(id: UUID, relativePath: String?, focusRelativePath: String?) -> Result<VoidResponse, Error> {
        var result: Result<VoidResponse, Error> = .failure(Self.notFoundError)

        context.performAndWait {
            let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            do {
                guard let dataToEdit = try context.fetch(fetchRequest).first else {
                    result = .failure(Self.notFoundError)
                    return
                }

                dataToEdit.relativePath = relativePath
                dataToEdit.focusRelativePath = focusRelativePath

                try context.save()
                result = .success(VoidResponse())
            } catch {
                context.rollback()
                result = .failure(error)
            }
        }

        return result
    }

    private static func makeLocation(from paperData: PaperData) -> PaperFileLocation {
        PaperFileLocation(
            id: paperData.id,
            title: paperData.title,
            url: paperData.url,
            relativePath: paperData.relativePath,
            focusURL: paperData.focusURL,
            focusRelativePath: paperData.focusRelativePath
        )
    }

    private static let notFoundError = NSError(
        domain: "",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "Data not found"]
    )
}
