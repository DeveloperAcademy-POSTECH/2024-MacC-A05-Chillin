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
              let provider = item.attachments?.first,
              provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) else { return }
        
        
        provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { url, error in
            if let error = error {
                print(String(describing: error))
            }
            
            if let fileURL = url {
                print(fileURL)
                print(FileManager.default.fileExists(atPath: fileURL.path()))
                let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.chillin.reazy")!.appending(path: fileURL.lastPathComponent)
                
                if FileManager.default.fileExists(atPath: path.path()) {
                    try! FileManager.default.removeItem(at: path)
                }
                
                try! FileManager.default.copyItem(at: fileURL, to: path)
                print(FileManager.default.fileExists(atPath: path.path()))
                
                var components = URLComponents(string: "reazy://pdf")!
                components.queryItems = [URLQueryItem(name: "file", value: fileURL.lastPathComponent)]
                
                if let url = components.url {
                    if self.openURL(url) {
                        print("url scheme success")
                    } else {
                        print("url scheme failed!")
                    }
                    
                    self.extensionContext?.completeRequest(returningItems: nil)
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
