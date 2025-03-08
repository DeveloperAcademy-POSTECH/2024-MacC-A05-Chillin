//
//  TagViewModel.swift
//  Reazy
//
//  Created by 김예림 on 2/17/25.
//

import Foundation
import Combine

@MainActor
class TagViewModel: ObservableObject {
    
    private let tagViewUseCase: TagViewUseCase
    // MARK: - [부리] tags에 사용자가 만든 태그들 다 저장
    @Published public var tags: [Tag] = [] {
        didSet {
            selectedTags = selectedTags.filter { tagName in
                tags.contains(where: { $0.name == tagName })
            }
        }
    }
    @Published public var selectedTags: [String] = [] {
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
    
    @Published private var targetTagID: UUID
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        tagViewUseCase: TagViewUseCase,
        tags: [Tag] = (1...20).map { Tag(name: "어쩌고\($0)") }
    ) {
        self.tagViewUseCase = tagViewUseCase
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
    }
    
    func tagTapped(for tagName: String){
        if let index = selectedTags.firstIndex(of: tagName) {
                selectedTags.remove(at: index)
            } else {
                selectedTags.append(tagName)
            }
    }
    
    func showDeleteAlert(id: UUID) {
        self.targetTagID = id
        self.showDeleteAlert = true
    }
    
    func getTagName() -> String {
        guard let tag = tags.first(where: { $0.id == targetTagID }) else {return ""}
        return tag.name
    }
    
    func deleteTag() {
        tagViewUseCase.deleteTag(id: targetTagID, from: &tags)
        self.showDeleteAlert = false
    }

    func createTag(name: String) {
        tagViewUseCase.createTag(name: name, in: &tags)
    }
}
