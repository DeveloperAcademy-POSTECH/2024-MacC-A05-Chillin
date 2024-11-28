//
//  ActionViewController.swift
//  action-extension
//
//  Created by 문인범 on 11/19/24.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
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
