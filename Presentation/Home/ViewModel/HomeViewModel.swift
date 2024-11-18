//
//  HomeViewModel.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation


@MainActor
class HomeViewModel: ObservableObject {
    @Published public var paperInfos: [PaperInfo] = []
    @Published public var isLoading: Bool = false
    @Published public var memoText: String = ""
    @Published public var errorStatus: PDFUploadError = .failedToAccessingSecurityScope
    
    private let homeViewUseCase: HomeViewUseCase
    
    init(homeViewUseCase: HomeViewUseCase) {
        self.homeViewUseCase = homeViewUseCase
        
        switch homeViewUseCase.loadPDFs() {
        case .success(let paperInfos):
            self.paperInfos = paperInfos
        case .failure(let error):
            print(error)
            return
        }
    }
}


extension HomeViewModel {
    public func uploadPDF(url: [URL]) -> UUID? {
        do {
            let paperInfo = try self.homeViewUseCase.uploadPDFFile(url: url)
            if paperInfo != nil {
                self.paperInfos.append(paperInfo!)
            }
            return paperInfo?.id
        } catch {
            if let error = error as? PDFUploadError {
                self.errorStatus = error
            }
            print(error)
            return nil
        }
    }
    
    public func uploadSamplePDF() -> UUID? {
        let paperInfo = self.homeViewUseCase.uploadSamplePDFFile()
        
        if paperInfo != nil {
            self.paperInfos.append(paperInfo!)
        }
        
        return paperInfo?.id
    }
    
    public func deletePDF(ids: [UUID]) {
        self.homeViewUseCase.deletePDFs(id: ids)
        ids.forEach { id in
            self.paperInfos.removeAll(where: { $0.id == id })
        }
    }
}


extension HomeViewModel {
    public func updateMemo(at id: UUID, memo: String) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].memo = memo
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func deleteMemo(at id: UUID) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].memo = nil
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
}


extension HomeViewModel {
    public func updateFavorite(at id: UUID, isFavorite: Bool) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].isFavorite = isFavorite
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func updateFavorites(at ids: [UUID]) {
        ids.forEach { id in
            if let index = paperInfos.firstIndex(where: { $0.id == id }) {
                paperInfos[index].isFavorite = true
                self.homeViewUseCase.editPDF(paperInfos[index])
            }
        }
    }
    
    public func updateLastModifiedDate(at id: UUID, lastModifiedDate: Date) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].lastModifiedDate = lastModifiedDate
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func updateIsFigureSaved(at id: UUID, isFigureSaved: Bool) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].isFigureSaved = isFigureSaved
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
    
    public func updateTitle(at id: UUID, title: String) {
        if let index = paperInfos.firstIndex(where: { $0.id == id }) {
            paperInfos[index].title = title
            self.homeViewUseCase.editPDF(paperInfos[index])
        }
    }
}


extension HomeViewModel {
    public func uploadSampleData() {
        let sampleUrl = Bundle.main.url(forResource: "engPD5", withExtension: "pdf")!
        self.paperInfos.append(PaperInfo(
            title: "A review of the global climate change impacts, adaptation, and sustainable mitigation measures",
            thumbnail: .init(),
            url: try! Data(contentsOf: sampleUrl),
            isFavorite: false,
            memo: "test",
            isFigureSaved: false
        ))
    }
}


