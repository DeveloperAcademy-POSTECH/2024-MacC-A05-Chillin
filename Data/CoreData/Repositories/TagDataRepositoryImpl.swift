//
//  TagDataRepositoryImpl.swift
//  Reazy
//
//  Created by 유지수 on 2/16/25.
//

import Foundation
import CoreData

final class TagDataRepositoryImpl: TagDataRepository {
    private let container: NSPersistentContainer = PersistantContainer.shared.container
    
    func fetchAllTags() -> Result<[Tag], any Error> {
        let dataContext = container.viewContext
        let fetchRequest: NSFetchRequest<TagData> = TagData.fetchRequest()
        
        do {
            let tags = try dataContext.fetch(fetchRequest)
            let tagList = tags.map { tag in
                Tag(id: tag.id, name: tag.name)
            }
            return .success(tagList)
        } catch {
            return .failure(error)
        }
    }
    
    func fetchPapersByTag(tagID: UUID) -> Result<[PaperInfo], any Error> {
        let dataContext = container.viewContext
        
        do {
            let tagFetch: NSFetchRequest<TagData> = TagData.fetchRequest()
            tagFetch.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            
            guard let tag = try dataContext.fetch(tagFetch).first else {
                return .success([]) // 태그가 없을 경우 빈 배열을 반환
            }
            
            let paperTagFetch: NSFetchRequest<PaperTag> = PaperTag.fetchRequest()
            paperTagFetch.predicate = NSPredicate(format: "tagData == %@", tag)
            
            let paperTags = try dataContext.fetch(paperTagFetch)
            // 아직 CloudKit 동기화가 끝나지 않아 관계가 비어 있는 항목은 건너뛴다.
            // 동기화가 완료되면 automaticallyMergesChangesFromParent로 다시 반영된다
            let papers = paperTags.compactMap { paperTag -> PaperInfo? in
                guard let paper = paperTag.paperData else { return nil }
                
                let tags = Array(paper.paperTags ?? []).compactMap { tagRelation -> Tag? in
                    guard let tagData = tagRelation.tagData else { return nil }
                    return Tag(id: tagData.id, name: tagData.name)
                }
                
                return PaperInfo(
                    id: paper.id,
                    title: paper.title,
                    thumbnail: paper.thumbnail,
                    url: paper.url,
                    focusURL: paper.focusURL,
                    lastModifiedDate: paper.lastModifiedDate,
                    isFavorite: paper.isFavorite,
                    isFigureSaved: paper.isFigureSaved,
                    folderID: paper.folderID ?? nil,
                    tags: tags
                )
            }
            
            return .success(papers)
        } catch {
            return .failure(error)
        }
    }
    
    func addTag(name: String) -> Result<Tag, any Error> {
        let dataContext = container.viewContext
        
        do {
            let tagFetch: NSFetchRequest<TagData> = TagData.fetchRequest()
            tagFetch.predicate = NSPredicate(format: "name == %@", name)
            
            let existingTags = try dataContext.fetch(tagFetch)
            if let existingTag = existingTags.first {
                return .success(Tag(id: existingTag.id, name: existingTag.name))
            }
            
            let newTag = TagData(context: dataContext)
            newTag.id = UUID()
            newTag.name = name
            
            AnalyticsManager.sendParameterlessEvent(eventType: .tagCreate)
            return .success(Tag(id: newTag.id, name: newTag.name))
        } catch {
            return .failure(error)
        }
    }
    
    func deleteTag(tagID: UUID) -> Result<VoidResponse, any Error> {
        let dataContext = container.viewContext
        
        do {
            let tagFetch: NSFetchRequest<TagData> = TagData.fetchRequest()
            tagFetch.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            
            guard let tag = try dataContext.fetch(tagFetch).first else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "TagData not found"]))
            }
            
            let paperTagFetch: NSFetchRequest<PaperTag> = PaperTag.fetchRequest()
            paperTagFetch.predicate = NSPredicate(format: "tagData = %@", tag)
            
            let paperTags = try dataContext.fetch(paperTagFetch)
            for paperTag in paperTags {
                dataContext.delete(paperTag)
            }
            
            dataContext.delete(tag)
            
            return .success(VoidResponse())
        } catch {
            return .failure(error)
        }
    }
    
    func renameTag(tagID: UUID, newName: String) -> Result<Tag, any Error> {
        let dataContext = container.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<TagData> = TagData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            
            guard let tag = try dataContext.fetch(fetchRequest).first else {
                return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "TagData not found"]))
            }
            
            tag.name = newName
            try dataContext.save()
            
            return .success(Tag(id: tag.id, name: tag.name))
        } catch {
            return .failure(error)
        }
    }
    
    func saveContext() throws {
        let context = container.viewContext
        try context.save()
    }
    
    func discardContext() {
        let context = container.viewContext
        context.rollback()
    }
}
