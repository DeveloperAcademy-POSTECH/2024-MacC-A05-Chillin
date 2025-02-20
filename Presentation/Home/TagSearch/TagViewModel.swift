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
    @Published public var tags: [TemporaryTag] = []
    @Published public var selectedTags: [String] = [] {
        didSet {
            isTagSelected = !selectedTags.isEmpty
        }
    }
    @Published public private(set) var isTagExist: Bool = false
    @Published public var isTagSelected: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init(
        tagViewUseCase: TagViewUseCase,
        tags: [TemporaryTag] = (1...50).map { TemporaryTag(name: "어쩌고\($0)") }
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
}
