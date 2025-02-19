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
    @Published public var selectedTags: [String] = []
    @Published public private(set) var isTagExist: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // cell너비가 text 길이에 맞게 조절되도록 하기
    // 선택한 칩스 배열에 타이틀 저장 -> 선택된 태그 목록에 뜨도록 하기
    
    init(
        tagViewUseCase: TagViewUseCase,
        tags: [TemporaryTag] = (1...50).map { TemporaryTag(name: "어쩌고\($0)") },
        selectedTags: [String] = []
    ) {
        self.tagViewUseCase = tagViewUseCase
        self.tags = tags
        self.selectedTags = selectedTags
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
    
    func cellTapped(title: String){
        self.selectedTags.append(title)
    }
}
