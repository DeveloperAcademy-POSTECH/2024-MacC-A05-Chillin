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
