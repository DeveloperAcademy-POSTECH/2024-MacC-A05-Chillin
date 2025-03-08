//
//  TagViewUseCase.swift
//  Reazy
//
//  Created by 김예림 on 2/17/25.
//

import Foundation

//MARK: - TODO : - 코어데이터 연결
protocol TagViewUseCase {
    func deleteTag(id: UUID, from tags: inout [Tag])
    func createTag(name: String, in tags: inout [Tag])
}

class DefaultTagViewUseCase: TagViewUseCase {
    func deleteTag(id: UUID, from tags: inout [Tag]) {
        tags.removeAll { $0.id == id }
    }
    
    func createTag(name: String, in tags: inout [Tag]) {
        tags.append(Tag(name: name))
    }
}
