//
//  ShareViewController.swift
//  share-extension
//
//  Created by 문인범 on 11/20/24.
//

import UIKit
import Social
import UniformTypeIdentifiers


class ShareViewController: SLComposeServiceViewController {
    override func viewWillAppear(_ animated: Bool) {
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
              let providers = item.attachments else { return }
        
        var components = URLComponents(string: "reazy://pdf")!
        var queryItems = [URLQueryItem]()
        
        let count = providers.count
        var currentCount = 1
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { url, error in
                    if let error = error {
                        print(String(describing: error))
                        return
                    }
                    
                    if let fileURL = url {
                        let manager = FileManager.default
                        
                        let groupFilePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.chillin.reazy")!
                            .appending(path: fileURL.lastPathComponent)
                        
                        if let _ = try? Data(contentsOf: groupFilePath) {
                            try! manager.removeItem(at: groupFilePath)
                        }
                        
                        try! FileManager.default.copyItem(at: fileURL, to: groupFilePath)
                        queryItems.append(.init(name: "file", value: fileURL.lastPathComponent))
                    }
                    
                    if currentCount == count {
                        components.queryItems = queryItems
                        
                        if let url = components.url {
                            if self.openURL(url) {
                                print("url scheme success")
                            } else {
                                print("url scheme failed")
                            }
                        }
                        
                        self.extensionContext?.completeRequest(returningItems: nil)
                    }
                    
                    currentCount += 1
                }
            }
        }
    }

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

    
    @objc
    func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return true
            }
            responder = responder?.next
        }
        return false
    }
}
