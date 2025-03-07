//
//  TagControlViewModel.swift
//  Reazy
//
//  Created by 문인범 on 3/7/25.
//

import Foundation


@MainActor
final class TagControlViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var searchedTags = [Tag]()
    @Published public var isLoading = false
    
    public var showingSearchPlaceholder: Bool {
        !isLoading && searchedTags.isEmpty && searchText.isEmpty
    }
    
    public var showingCreateNewTag: Bool {
        !isLoading && searchedTags.isEmpty && !searchText.isEmpty
    }
    
    public var showingExistingTags: Bool {
        !isLoading && !searchedTags.isEmpty
    }
    
    private var timer: Timer?
    
    
    
    private let useCase: TagControlUseCase
    init(useCase: TagControlUseCase) {
        self.useCase = useCase
    }
    
}



extension TagControlViewModel {
    public func searchTagButtonTapped() {
        guard !searchText.isEmpty else { return }
        self.isLoading = true
        
        if let timer = timer {
            timer.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.loadSearchedTags()
            }
        }
    }
    
    
    public func loadSearchedTags() {
        defer { self.isLoading = false }
        
        do {
            let response = try self.useCase.searchTags(searchText)
            searchedTags = response
        } catch {
            
        }
    }
    
    public func createNewTagButtonTapped() {
        guard !searchText.isEmpty else { return }
        
        self.useCase.createTag(searchText)
    }
    
    public func tagTest() {
        self.useCase.createTag("Reazy")
        self.useCase.createTag("Cognitive")
        self.useCase.createTag("Axonal guidance")
    }
}
