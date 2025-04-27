//
//  TagViewModel.swift
//  Reazy
//
//  Created by 김예림 on 2/17/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class TagViewModel: ObservableObject {
    
    private let tagViewUseCase: TagViewWithIOUseCase
    
    @Published public var tags: [Tag] = []
    @Published public var selectedTags: [Tag] = [] {
        didSet {
            isTagSelected = !selectedTags.isEmpty
        }
    }
    @Published public private(set) var isTagExist: Bool = false
    @Published public var isTagSelected: Bool = false
    @Published public var isBtnTapped: Bool = false
    @Published public var isEditMode: Bool = false
    @Published public var popover: Bool = false
    @Published public var createTag: Bool = false
    @Published public var isTagDuplicate: Bool = false
    @Published public var showDeleteAlert: Bool = false
    @Published public var listWidth: CGFloat = 0
    
    @Published private var targetTagID: UUID
    
    @Published public var tagFilteredPapers: [PaperInfo] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        tagViewUseCase: TagViewWithIOUseCase
    ) {
        self.tagViewUseCase = tagViewUseCase
        let tags = tagViewUseCase.fetchTags()
        
        self.tags = tags
        self.isTagExist = !tags.isEmpty
        self.targetTagID = UUID()
        setBindings()
    }
    
    private func setBindings() {
        $tags
            .map { !$0.isEmpty }
            .assign(to: \.isTagExist, on: self)
            .store(in: &cancellables)
        
        $selectedTags
            .map {
                self.tagViewUseCase.fetchFilteredPaperList(tags: $0)
            }
            .assign(to: \.tagFilteredPapers, on: self)
            .store(in: &cancellables)
    }
    
    deinit {
        self.cancellables.forEach { $0.cancel() }
    }
    
    func tagTapped(for tagName: String){
        guard let index = tags.firstIndex(where: { $0.name == tagName }) else { return }
        tags[index].isSelected.toggle()
        
        if tags[index].isSelected {
            selectedTags.append(tags[index])
        } else {
            selectedTags.removeAll { $0.id == tags[index].id }
        }
    }
    
    func showDeleteAlert(id: UUID) {
        self.targetTagID = id
        withAnimation {
            self.showDeleteAlert = true
        }
    }
    
    func getTagName() -> String {
        guard let tag = tags.first(where: { $0.id == targetTagID }) else {return ""}
        return tag.name
    }
    
    func deleteTag() {
        if (tagViewUseCase.deleteTag(id: targetTagID)) {
            tags.removeAll{ $0.id == targetTagID }
            selectedTags.removeAll(){ $0.id == targetTagID }
        } else {
            // Error 처리
        }
        withAnimation {
            self.showDeleteAlert = false
        }
    }

    func createTag(name: String) {
        do {
            let newTag = try tagViewUseCase.createTag(name: name)
            self.tags.append(newTag)
        } catch {
            
        }
    }
    
    public func fetchTags() {
        self.tags = self.tagViewUseCase.fetchTags()
        
        for selectedTag in selectedTags {
            if let index = tags.firstIndex(where: { $0.id == selectedTag.id }) {
                tags[index].isSelected = true
            }
        }
    }
}

// MARK: Ellipsis Actions
extension TagViewModel {
    public func starButtonTapped(paperInfo: PaperInfo) {
        let modifiedPaperInfo = PaperInfo(
            id: paperInfo.id,
            title: paperInfo.title,
            thumbnail: paperInfo.thumbnail,
            url: paperInfo.url,
            focusURL: paperInfo.focusURL,
            lastModifiedDate: paperInfo.lastModifiedDate,
            isFavorite: !paperInfo.isFavorite,
            isFigureSaved: paperInfo.isFavorite,
            folderID: paperInfo.folderID,
            tags: paperInfo.tags
        )
        
        if let idx = tagFilteredPapers.firstIndex(where: {$0.id == paperInfo.id}) {
            tagFilteredPapers[idx].isFavorite = modifiedPaperInfo.isFavorite
        }
        
        tagViewUseCase.editPDF(modifiedPaperInfo)
    }
    
    public func copyButtonTapped(paperInfo: PaperInfo) {
        let response = tagViewUseCase.duplicatePDF(paperInfo)
        
        if case .success = response {
            fetchFilteredPaperList()
        } else {
            print(#function)
        }
    }
    
    func getlistWidth(width: CGFloat) {
        listWidth = width - 40
    }

    public func deleteButtonTapped(paperInfo: PaperInfo) {
        let id = paperInfo.id
        
        tagViewUseCase.deletePDF(paperInfo)
        if let index = tagFilteredPapers.firstIndex(where: { $0.id == id }) {
            tagFilteredPapers.remove(at: index)
        }
    }
    
    public func fetchFilteredPaperList() {
        self.tagFilteredPapers = self.tagViewUseCase.fetchFilteredPaperList(tags: self.selectedTags)
    }
}

struct TagPopoverPositionKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
}
