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
    @Published public var tags: [Tag] = []
    @Published public var selectedTags: [String] = [] {
        didSet {
            isTagSelected = !selectedTags.isEmpty
        }
    }
    @Published public private(set) var isTagExist: Bool = false
    @Published public var isTagSelected: Bool = false
    @Published public var isEditMode: Bool = false
    @Published public var popover: Bool = false
    @Published public var createTag: Bool = false
    @Published public var isTagDuplicate: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init(
        tagViewUseCase: TagViewUseCase,
        tags: [Tag] = (1...50).map { Tag(name: "어쩌고\($0)") }
    ) {
        self.tagViewUseCase = tagViewUseCase
        self.tags = tags
        self.isTagExist = !self.tags.isEmpty
        setBindings()
        print(self.isTagExist)
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
    
    func deleteTag(id: UUID) {
        tags.removeAll { $0.id == id }
    }
    
    func createTag(name: String) {
        tags.append(Tag(name: name))
    }
}
