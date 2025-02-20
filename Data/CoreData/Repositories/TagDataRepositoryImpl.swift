//
//  TagDataRepositoryImpl.swift
//  Reazy
//
//  Created by 유지수 on 2/16/25.
//

import Foundation
import CoreData

class TagDataRepositoryImpl: TagDataRepository {
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
            let papers = paperTags.map { paperTag in
                let paper = paperTag.paperData
                
                let tags = Array(paper.paperTags ?? []).map { tagRelation in
                    Tag(id: tagRelation.tagData.id, name: tagRelation.tagData.name)
                }
                
                return PaperInfo(
                    id: paperTag.paperData.id,
                    title: paperTag.paperData.title,
                    thumbnail: paperTag.paperData.thumbnail,
                    url: paperTag.paperData.url,
                    focusURL: paperTag.paperData.focusURL,
                    lastModifiedDate: paperTag.paperData.lastModifiedDate,
                    isFavorite: paperTag.paperData.isFavorite,
                    isFigureSaved: paperTag.paperData.isFigureSaved,
                    folderID: paperTag.paperData.folderID ?? nil,
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
            
            try dataContext.save()
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
            try dataContext.save()
            
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
}
