//
//  HomeViewUseCase.swift
//  Reazy
//
//  Created by 문인범 on 11/17/24.
//

import Foundation
import SwiftUI
import PDFKit
import RegexBuilder


protocol BasicPaperCRUDUseCase {
    func loadPDFs() -> Result<[PaperInfo], any Error>
    
    @discardableResult
    func savePDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editPDF(_ info: PaperInfo) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deletePDF(id: UUID) -> Result<VoidResponse, any Error>
}


typealias HomeViewUseCase = BasicPaperCRUDUseCase & BasicHomeViewUseCase


protocol BasicHomeViewUseCase {
    func duplicatePDF(paperInfo: PaperInfo) throws -> PaperInfo?
    
    func uploadPDFFile(url: [URL], folderID: UUID?) throws -> PaperInfo?
  
    func savePDFIntoDirectory(url: URL, isSample: Bool) throws -> (Data, URL)?
    
    func uploadSamplePDFFile() -> [PaperInfo?]
    
    func loadFolders() -> Result<[Folder], any Error>
    
    @discardableResult
    func saveFolder(_ folder: Folder) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func editFolder(_ folder: Folder) -> Result<VoidResponse, any Error>
    
    @discardableResult
    func deleteFolder(id: UUID) -> Result<VoidResponse, any Error>
}


class DefaultBasicPaperCRUDUseCase: BasicPaperCRUDUseCase {
    private let paperDataRepository: PaperDataRepository
    
    init(paperDataRepository: PaperDataRepository) {
        self.paperDataRepository = paperDataRepository
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
    
    /// 홈 목록 셀에 82x110pt로 표시되므로 페이지 원본 크기 그대로 저장할 필요가 없다.
    /// CloudKit은 레코드 하나당 약 1MB 제한이 있어서, 큰 판형이거나 그림이 많은 페이지를
    /// 무압축 PNG로 넣으면 그 논문만 조용히 동기화에 실패한다
    private static let thumbnailMaxLength: CGFloat = 600
    
    private func makeThumbnailData(from page: PDFPage) -> Data? {
        let pageSize = page.bounds(for: .mediaBox).size
        guard pageSize.width > 0, pageSize.height > 0 else { return nil }
        
        let scale = min(1, Self.thumbnailMaxLength / max(pageSize.width, pageSize.height))
        let targetSize = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
        
        return page.thumbnail(of: targetSize, for: .mediaBox).jpegData(compressionQuality: 0.8)
    }
    
    public func uploadPDFFile(url: [URL], folderID: UUID?) throws -> PaperInfo? {
        guard let url = url.first else { return nil }
        
        let _ = url.startAccessingSecurityScopedResource()
        defer { url.stopAccessingSecurityScopedResource() }

        guard let urlData = try? self.savePDFIntoDirectory(url: url, isSample: false) else {
            throw PDFUploadError.fileNameDuplication
        }
        
        let tempDoc = PDFDocument(url: urlData.1)
        
        let title = urlData.1.deletingPathExtension().lastPathComponent
        
        if let firstPage = tempDoc?.page(at: 0),
           let thumbnailData = self.makeThumbnailData(from: firstPage) {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: thumbnailData,
                url: urlData.0,
                relativePath: PaperFileLocator.storageRelativePath(of: urlData.1),
                folderID: folderID
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            
            return paperInfo
            
        } else {
            let paperInfo = PaperInfo(
                title: title,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: urlData.0,
                relativePath: PaperFileLocator.storageRelativePath(of: urlData.1),
                folderID: folderID
            )
            
            self.paperDataRepository.savePDFInfo(paperInfo)
            return paperInfo
        }
    }
    
    public func uploadSamplePDFFile() -> [PaperInfo?] {
        let guideURL = Locale.currentLangGuideURL()
        let sampleURL = Bundle.main.url(forResource: "Reazy Sample Paper", withExtension: "pdf")!
        
        let guideTempDoc = PDFDocument(url: guideURL)
        let sampleTempDoc = PDFDocument(url: sampleURL)
        
        let guideURLData = try! self.savePDFIntoDirectory(url: guideURL, isSample: true)!
        let sampleURLData = try! self.savePDFIntoDirectory(url: sampleURL, isSample: true)!
        
        let guideTitle = guideURLData.1.deletingPathExtension().lastPathComponent
        let sampleTitle = sampleURLData.1.deletingPathExtension().lastPathComponent
        
        let sampleFocusURLData = self.makeSampleFocus(tempDoc: sampleTempDoc)
        
        if let guideFirstPage = guideTempDoc?.page(at: 0), let sampleFirstPage = sampleTempDoc?.page(at: 0),
           let guideThumbnailData = self.makeThumbnailData(from: guideFirstPage),
           let sampleThumbnailData = self.makeThumbnailData(from: sampleFirstPage) {
            let sampleFolder = Folder(id: .init(), title: "Reazy", color: "folder1", parentFolderID: nil)
            folderDataRepository.saveFolder(sampleFolder)
            
            let guidePaperInfo = PaperInfo(
                title: guideTitle,
                thumbnail: guideThumbnailData,
                url: guideURLData.0,
                relativePath: PaperFileLocator.storageRelativePath(of: guideURLData.1),
                isFigureSaved: true,
                folderID: sampleFolder.id
            )
            
            let samplePaperInfo = PaperInfo(
                title: sampleTitle,
                thumbnail: sampleThumbnailData,
                url: sampleURLData.0,
                relativePath: PaperFileLocator.storageRelativePath(of: sampleURLData.1),
                focusURL: sampleFocusURLData,
                isFigureSaved: true,
                folderID: sampleFolder.id
            )

            self.paperDataRepository.savePDFInfo(guidePaperInfo)
            self.paperDataRepository.savePDFInfo(samplePaperInfo)
            
            self.paperDataRepository.addTag(to: guidePaperInfo.id, with: "Sample")
            self.paperDataRepository.addTag(to: samplePaperInfo.id, with: "Sample")
            
            return [guidePaperInfo, samplePaperInfo]
        } else {
            let guidePaperInfo = PaperInfo(
                title: guideTitle,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: guideURLData.0,
                relativePath: PaperFileLocator.storageRelativePath(of: guideURLData.1),
                isFigureSaved: true
            )
            
            let samplePaperInfo = PaperInfo(
                title: sampleTitle,
                thumbnail: UIImage(resource: .testThumbnail).pngData()!,
                url: sampleFocusURLData,
                focusURL: sampleFocusURLData,
                isFigureSaved: true
            )

            self.paperDataRepository.savePDFInfo(guidePaperInfo)
            self.paperDataRepository.savePDFInfo(samplePaperInfo)
            
            return [guidePaperInfo, samplePaperInfo]
        }
    }
    
    private func makeSampleFocus(tempDoc: PDFDocument?) -> Data {
        let path = FileManager.default.pdfStorageDirectory
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

        let focusURLData = try! path.bookmarkData(options: .suitableForBookmarkFile)
        
        return focusURLData
    }
    
    public func duplicatePDF(paperInfo: PaperInfo) throws -> PaperInfo? {
        do {
            guard let originalUrl = PaperFileLocator.resolve(paperInfo)?.url else {
                throw PDFUploadError.fileNameDuplication
            }
            
            if let (data, url) = self.copyItem(url: originalUrl) {
                
                let newPaperInfo = PaperInfo(
                    title: url.deletingPathExtension().lastPathComponent,
                    thumbnail: paperInfo.thumbnail,
                    url: data,
                    relativePath: PaperFileLocator.storageRelativePath(of: url),
                    focusURL: paperInfo.focusURL,
                    lastModifiedDate: Date(),
                    isFavorite: false,
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
            let documentURL = manager.pdfStorageDirectory
            let fileURL = documentURL.appending(path: url.lastPathComponent)
            
            if let _ = try? Data(contentsOf: fileURL) {
                return self.copyItem(url: fileURL)
            }
                        
            let _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            var error: NSError?
            
            // 업로드 전 로컬에 다운로드 진행
            NSFileCoordinator().coordinate(readingItemAt: url, options: .forUploading, error: &error) { _ in
//                print("coordinated URL: \(cloudURL)")
            }
            
            try manager.copyItem(at: url, to: fileURL)
            
            let urlData = try fileURL.bookmarkData(options: .suitableForBookmarkFile)
            
            return (urlData, fileURL)
        } catch {
            log("error copying file: \(error)")
        }
        
        return nil
    }
    
    internal func copyItem(url: URL) -> (Data, URL)? {
        do {
            let manager = FileManager.default
            let documentURL = manager.pdfStorageDirectory
            let fileURL = documentURL.appending(path: url.lastPathComponent)
            
            var error: NSError?
            
            // 업로드 전 로컬에 다운로드 진행
            NSFileCoordinator().coordinate(readingItemAt: url, options: .forUploading, error: &error) { _ in
//                print("coordinated URL: \(cloudURL)")
            }
            
            let lastComponent = url.deletingPathExtension().lastPathComponent
            var splitComp = lastComponent.split(separator: " ")
            
            let regex = Regex {
                "("
                OneOrMore(.digit)
                ")"
            }
            
            if let splitCompLast = splitComp.last?.prefixMatch(of: regex) {
                var fileNumString = splitCompLast.output
                fileNumString.removeFirst()
                fileNumString.removeLast()
                
                splitComp.removeLast()
                let fileName = splitComp.joined(separator: " ")
                
                var fileNum = Int(fileNumString)!
                
                while(fileNum < 9999) {
                    let resultURL = documentURL.appending(path: fileName + " (\(fileNum+1)).pdf")
                    
                    if let _ = try? Data(contentsOf: resultURL) {
                        fileNum += 1
                        continue
                    }
                    
                    try manager.copyItem(at: url, to: resultURL)
                    let bookmarkData = try resultURL.bookmarkData(options: .suitableForBookmarkFile)
                    return (bookmarkData, resultURL)
                }
            } else {
                var num = 1
                while(num < 9999) {
                    let resultURL = documentURL.appending(path: lastComponent + " (\(num)).pdf")
                    
                    if let _ = try? Data(contentsOf: resultURL) {
                        num += 1
                        continue
                    }
                    
                    try manager.copyItem(at: fileURL, to: resultURL)
                    let urlData = try resultURL.bookmarkData(options: .suitableForBookmarkFile)
                    
                    return (urlData, resultURL)
                }
            }
        } catch {
            log("error copying file: \(error)")
        }
        
        return nil
    }
    
    private func sampleTagUpload(_ paperId: UUID) {
        let repository = PaperDataRepositoryImpl()
        
        let _ = repository.addTag(to: paperId, with: "reazy")
        let _ = repository.addTag(to: paperId, with: "한국어")
        let _ = repository.addTag(to: paperId, with: "Heat Transfer")
    }
}
