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

    func fetchAllPaperLocations() -> Result<[PaperFileLocation], Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()

        do {
            let fetchedDataList = try dataContext.fetch(fetchRequest)
            let locations = fetchedDataList.map { paperData in
                PaperFileLocation(id: paperData.id, url: paperData.url, focusURL: paperData.focusURL)
            }
            return .success(locations)
        } catch {
            return .failure(error)
        }
    }

    func fetchPaperLocation(id: UUID) -> Result<PaperFileLocation, Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            guard let paperData = try dataContext.fetch(fetchRequest).first else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data not found"]))
            }
            return .success(PaperFileLocation(id: paperData.id, url: paperData.url, focusURL: paperData.focusURL))
        } catch {
            return .failure(error)
        }
    }

    func updateFileLocation(id: UUID, url: Data, focusURL: Data?) -> Result<VoidResponse, Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<PaperData> = PaperData.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            guard let dataToEdit = try dataContext.fetch(fetchRequest).first else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Data not found"]))
            }

            dataToEdit.url = url
            dataToEdit.focusURL = focusURL

            try dataContext.save()
            return .success(VoidResponse())
        } catch {
            return .failure(error)
        }
    }
}
