//
//  HomeViewUseCase.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation
import SwiftUI
import PDFKit


protocol HomeViewUseCase {
    func loadPDFs() -> Result<[PaperInfo], any Error>
    
    @discardableResult
    func savePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deletePDF(id: UUID) -> Result<VoidResponse, any Error>
    
    func uploadPDFFile(url: [URL], folderID: UUID?) throws -> PaperInfo?
  
    func savePDFIntoDirectory(url: URL, isSample: Bool) throws -> (Data, URL)?
    
    func uploadSamplePDFFile() -> PaperInfo?
    
    func loadFolders() -> Result<[Folder], any Error>
    
    @discardableResult
    func saveFolder(_ folder: Folder) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editFolder(_ folder: Folder) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deleteFolder(id: UUID) -> Result<VoidResponse, any Error>
}


class DefaultHomeViewUseCase: HomeViewUseCase {
    private let paperDataRepository: PaperDataRepository
    private let folderDataRepository: FolderDataRepository
    
    init(paperDataRepository: PaperDataRepository, folderDataRepository: FolderDataRepository) {
        self.paperDataRepository = paperDataRepository
        self.folderDataRepository = folderDataRepository
    }
    
    public func loadPDFs() -> Result<[PaperInfo], any Error> {
        self.paperDataRepository.loadPDFInfo()
    }
    
    public func savePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.savePDFInfo(info)
    }
    
    public func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.editPDFInfo(info)
    }
    
    public func deletePDF(id: UUID) -> Result<VoidResponse, any Error> {
        self.paperDataRepository.deletePDFInfo(id: id)
    }
    
    public func uploadPDFFile(url: [URL], folderID: UUID?) throws -> PaperInfo? {
        guard let url = url.first else { return nil }
        
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        let tempDoc = PDFDocument(url: url)
        
        guard let urlData = try? self.savePDFIntoDirectory(url: url, isSample: false) else {
            throw PDFUploadError.fileNameDuplication
        }
        
        var lastComponent = urlData.1.lastPathComponent.split(separator: ".")
        lastComponent.removeLast()
        
        let title = lastComponent.joined()
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData.0,
                folderID: folderID
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData.0,
                folderID: folderID
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    public func uploadSamplePDFFile() -> PaperInfo? {
        let pdfURL = Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!
        
        let tempDoc = PDFDocument(url: pdfURL)

        let urlData = try! self.savePDFIntoDirectory(url: pdfURL, isSample: true)!
        
        var lastComponent = pdfURL.lastPathComponent.split(separator: ".")
        lastComponent.removeLast()
        
        let title = lastComponent.joined()
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "ReazySamplePaper_combine.pdf")
        
        let layout = try! JSONDecoder()
            .decode(
                PDFLayoutResponseDTO.self,
                from: try! .init(contentsOf: Bundle.main.url(forResource: "sample", withExtension: "json")!))
        
        let focuses = layout.toFocusEntities(pageHeight: tempDoc!.page(at: 0)!.bounds(for: .mediaBox).height)
        
        let w: CGFloat = {
            var result: CGFloat = 0
            for annotation in focuses {
                if annotation.position.width > result {
                    result = annotation.position.width
                }
            }
            return result
        }()
        
        let height: CGFloat = {
            var result: CGFloat = 0
            for annotation in focuses {
                result += annotation.position.height
            }
            return result
        }()
        
        UIGraphicsBeginPDFContextToFile(path.path(), CGRect(origin: .zero, size: .init(width: w + 60, height: height + 20)), nil)
        UIGraphicsBeginPDFPageWithInfo(CGRect(origin: .zero, size: .init(width: w + 60, height: height + 20)), nil)
        
        var currentY: CGFloat = 20
        
        for annotation in focuses {
                // Render the page content
                if let context = UIGraphicsGetCurrentContext() {
                    let page = tempDoc!
                        .page(at: annotation.page - 1)!.copy() as! PDFPage
                    
                    let crop = annotation.position
                    
                    let original = page.bounds(for: .mediaBox)
                    let croppedRect = original.intersection(crop)
                    page.displaysAnnotations = false
                    
                    page.setBounds(croppedRect, for: .mediaBox)
                    
                    context.saveGState()
                    context.translateBy(x: 0, y: currentY + annotation.position.height) // Adjust y-position
                    context.scaleBy(x: 1, y: -1) // Flip coordinate system
                    page.draw(with: .mediaBox, to: context) // Draw the page
                    context.restoreGState()
                }

                // Move to the next page's position
            currentY += annotation.position.height
        }
        
        UIGraphicsEndPDFContext()
        
        let focusURLData = try! path.bookmarkData(options: .minimalBookmark)
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData.0,
                focusURL: focusURLData
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData.0,
                focusURL: focusURLData
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    public func loadFolders() -> Result<[Folder], any Error> {
        self.folderDataRepository.loadFolders()
    }
    
    public func saveFolder(_ folder: Folder) -> Result<VoidResponse, any Error> {
        self.folderDataRepository.saveFolder(folder)
    }
    
    public func editFolder(_ folder: Folder) -> Result<VoidResponse, any Error> {
        self.folderDataRepository.editFolder(folder)
    }
    
    public func deleteFolder(id: UUID) -> Result<VoidResponse, any Error> {
        self.folderDataRepository.deleteFolder(id: id)
    }
      
    internal func savePDFIntoDirectory(url: URL, isSample: Bool) throws -> (Data, URL)? {
        do {
            let manager = FileManager.default
            let documentURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentURL.appending(path: url.lastPathComponent)
            
            // TODO: url 오류 대응
            if !isSample {
                guard url.startAccessingSecurityScopedResource() else { return nil }
                defer { url.stopAccessingSecurityScopedResource() }
            }
            
            if manager.fileExists(atPath: fileURL.path()) {
                var dupNum = 1
                
                var lastComponent = url.lastPathComponent.split(separator: ".")
                lastComponent.removeLast()
                
                
                while dupNum < 100 {
                    let tempURL = documentURL.appending(path: lastComponent.joined() + "(\(dupNum)).pdf")
                    
                    if !manager.fileExists(atPath: tempURL.path()) {
                        try manager.copyItem(at: url, to: tempURL)
                        return try (tempURL.bookmarkData(options: .minimalBookmark), tempURL)
                    }
                    
                    if dupNum == 99 {
                        throw PDFUploadError.fileNameDuplication
                    }
                    
                    dupNum += 1
                }
                
                
            } else {
                try manager.copyItem(at: url, to: fileURL)
            }
            
            let urlData = try fileURL.bookmarkData(options: .minimalBookmark)
            
            return (urlData, fileURL)
        } catch {
            print("error copying file: \(error)")
        }
        
        return nil
    }
}
