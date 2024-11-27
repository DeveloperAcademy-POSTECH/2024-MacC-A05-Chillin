//
//  PageListViewModel.swift
//  Reazy
//
//  Created by 문인범 on 11/16/24.
//

import UIKit
import PDFKit


@MainActor
class PageListViewModel: ObservableObject {
    @Published public var thumnailImages = [UIImage]()
    
    @Published public var changedPageNumber: Int?
    @Published public var selectedDestination: PDFDestination?
    
    private var pageListUseCase: PageListUseCase
    
    
    init(pageListUseCase: PageListUseCase) {
        self.pageListUseCase = pageListUseCase
    }
}


extension PageListViewModel {
    public func getPageThumbnails(completion: @escaping () -> Void) {
        guard let thumbnails = self.pageListUseCase.getThumbnailImage() else {
            return
        }
        
        DispatchQueue.main.async {
            self.thumnailImages = thumbnails
            completion()
        }
    }
    
    public func goToPage(at index: Int) {
        self.selectedDestination = self.pageListUseCase.goToPage(at: index)
    }
}

