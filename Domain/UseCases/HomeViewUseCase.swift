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
    
    func duplicatePDF(paperInfo: PaperInfo) throws -> PaperInfo?
    
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
        
        let _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }
        
        let tempDoc = PDFDocument(url: url)

        
        guard let urlData = try? self.savePDFIntoDirectory(url: url, isSample: false) else {
            throw PDFUploadError.fileNameDuplication
        }
        
        let title = urlData.1.deletingPathExtension().lastPathComponent
        
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
        let pdfURL = Bundle.main.url(forResource: "Reazy 사용 가이드", withExtension: "pdf")!
        
        let tempDoc = PDFDocument(url: pdfURL)
        let urlData = try! self.savePDFIntoDirectory(url: pdfURL, isSample: true)!
        
        let title = urlData.1.deletingPathExtension().lastPathComponent
        
        if let firstPage = tempDoc?.page(at: 0) {
            let width = firstPage.bounds(for: .mediaBox).width
            let height = firstPage.bounds(for: .mediaBox).height
            
            let image = firstPage.thumbnail(of: .init(width: width, height: height), for: .mediaBox)
            let thumbnailData = image.pngData()
            
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData!,
                url: urlData.0,
                isFigureSaved: true
            )

            self.paperDataRepository.savePDFInfo(paperInfo)

            return paperInfo
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData.0,
                isFigureSaved: true
            )

            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
        /*
        let pdfURL = Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!
        
        let tempDoc = PDFDocument(url: pdfURL)
        let urlData = try! self.savePDFIntoDirectory(url: pdfURL, isSample: true)!
        
        let title = urlData.1.deletingPathExtension().lastPathComponent

        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appending(path: "ReazySamplePaper_combine.pdf")

        let layout = try! JSONDecoder()
            .decode(
                PDFLayoutResponseDTO.self,
                from: try! .init(contentsOf: Bundle.main.url(forResource: "sample", withExtension: "json")!))

        let tempPath = FileManager.default.temporaryDirectory
            .appending(path: "combine.pdf")

        let focuses = layout.toFocusEntities(pageHeight: tempDoc!.page(at: 0)!.bounds(for: .mediaBox).height)

        let maxWidth: CGFloat = {
            var result: CGFloat = 0
            for focus in focuses {
                if focus.position.width > result {
                    result = focus.position.width
                }
            }
            return result
        }()

        let heightArray: [CGFloat] = {
            var result: [CGFloat] = []
            var headString = focuses.first!.header

            var temp: CGFloat = 0

            for focus in focuses {
                if headString != focus.header {
                    headString = focus.header
                    result.append(temp)
                    temp = 0
                }

                temp += focus.position.height
            }
            result.append(temp)
            
            return result
        }()

        let annotationArray: [[FocusAnnotation]] = {
            var resultArray: [[FocusAnnotation]] = []

            var head = focuses.first!.header

            var tempArray = [FocusAnnotation]()

            for focus in focuses {
                if focus.header != head {
                    head = focus.header
                    resultArray.append(tempArray)
                    tempArray.removeAll()
                }
                
                tempArray.append(focus)
            }
            resultArray.append(tempArray)
            return resultArray
        }()

        UIGraphicsBeginPDFContextToFile(tempPath.path(), .zero, nil)

        for (index, annotations) in annotationArray.enumerated() {
            let height = heightArray[index]

            UIGraphicsBeginPDFPageWithInfo(.init(origin: .zero, size: .init(width: maxWidth + 60, height: height)), nil)

            var currentY: CGFloat = 0

            for annotation in annotations {
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
                        context.translateBy(x: 30, y: currentY + annotation.position.height) // Adjust y-position
                        context.scaleBy(x: 1, y: -1) // Flip coordinate system
                        page.draw(with: .mediaBox, to: context) // Draw the page
                        context.restoreGState()
                    }

                    // Move to the next page's position
                currentY += annotation.position.height
            }
        }

        UIGraphicsEndPDFContext()

        try! FileManager.default.moveItem(at: tempPath, to: path)

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
         */
    }
    
    public func duplicatePDF(paperInfo: PaperInfo) throws -> PaperInfo? {
        var isStale = false
        
        do {
            let originalUrl = try URL.init(resolvingBookmarkData: paperInfo.url, bookmarkDataIsStale: &isStale)
            
            if let (data, url) = try self.savePDFIntoDirectory(url: originalUrl, isSample: false) {
                
                let newPaperInfo = PaperInfo(
                    title: url.deletingPathExtension().lastPathComponent,
                    thumbnail: paperInfo.thumbnail,
                    url: data,
                    focusURL: paperInfo.focusURL,
                    lastModifiedDate: Date(),
                    isFavorite: paperInfo.isFavorite,
                    memo: paperInfo.memo,
                    isFigureSaved: paperInfo.isFigureSaved,
                    folderID: paperInfo.folderID)
                
                self.paperDataRepository.duplicatePDFInfo(id: paperInfo.id, info: newPaperInfo)
                return newPaperInfo
            }
            
            throw PDFUploadError.fileNameDuplication
        } catch {
            throw PDFUploadError.fileNameDuplication
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
            
            let _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let _ = try? Data(contentsOf: fileURL) {
                var dupNum = 1
                
                
                var lastComponent = url.lastPathComponent.split(separator: ".")
                lastComponent.removeLast()
                
                
                while dupNum < 100 {
                    let tempURL = documentURL.appending(path: lastComponent.joined() + "(\(dupNum)).pdf")
                    
                    guard let _ = try? Data(contentsOf: tempURL) else {
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
