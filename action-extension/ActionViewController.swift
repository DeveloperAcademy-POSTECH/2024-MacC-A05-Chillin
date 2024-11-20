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
        /*
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    let returnItem = provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { (url, error) in
                        if let url = url as? URL {
                            print(UTType.pdf.identifier)
                            print(url)
//                            self.extensionContext!.completeRequest(returningItems: [url])
//                            let saveData = UserDefaults.init(suiteName: <#T##String?#>)
                            self.extensionContext?.open(.init(string: "reazy://ffff")!) {
                                print($0)
                            }
                            
                        }
                    }
                }
            }
        }
         */
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first,
              provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) else { return }
        
        
        provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { url, error in
            if let error = error {
                print("fasfasdfsd")
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
        
        
//        provider.loadItem(forTypeIdentifier: "public.pdf") { (url, error) in
//            if let error = error {
//                print("failed to load item")
//                return
//            }
//            
//            if let fileurl = url as? URL {
//                fileurl.startAccessingSecurityScopedResource()
//                
//                print(FileManager.default.fileExists(atPath: fileurl.path()))
//                
//                var components = URLComponents(string: "reazy://pdf")!
//                components.queryItems = [URLQueryItem(name: "file", value: fileurl.lastPathComponent)]
//                
//                if let url = components.url {
//                    if self.openURL(url) {
//                        print("url scheme success")
//                    } else {
//                        print("url scheme failed!")
//                    }
//                    
//                    
//                    self.extensionContext?.completeRequest(returningItems: nil)
//                }
//            }
//        }
        
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    
        // Get the item[s] we're handling from the extension context.
        
        // For example, look for an image and place it into an image view.
        // Replace this with something appropriate for the type[s] your extension supports.
//        var imageFound = false
//        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
//            for provider in item.attachments! {
//                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
//                    // This is an image. We'll load it, then place it in our image view.
//                    weak var weakImageView = self.imageView
//                    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { (imageURL, error) in
//                        if let imageURL = imageURL as? URL {
//                            Task { @MainActor in
//                                if let strongImageView = weakImageView {
//                                    strongImageView.image = UIImage(data: try! Data(contentsOf: imageURL))
//                                }
//                            }
//                        }
//                    }
//                    
//                    imageFound = true
//                    break
//                }
//            }
//            
//            if (imageFound) {
//                // We only handle one image, so stop looking for more.
//                break
//            }
//        }
        
//        if let url = URL(string: "reazy://ffff") {
//            self.openURL(url)
//        }
        
//        self.extensionContext!.open(.init(string: "https://google.com")!) {
//            print($0)
//        }
        
        /*
        for item in self.extensionContext!.inputItems as! [NSExtensionItem] {
            for provider in item.attachments! {
                if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    let returnItem = provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { (url, error) in
                        if let url = url as? URL {
                            print(UTType.pdf.identifier)
                            print(url)
//                            self.extensionContext!.completeRequest(returningItems: [url])
//                            let saveData = UserDefaults.init(suiteName: <#T##String?#>)
                            self.extensionContext?.open(.init(string: "reazy://ffff")!) {
                                print($0)
                            }
                            
                        }
                    }
                }
            }
        }
         */
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        //        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
        if let url = URL(string: "reazy://ffff") {
            self.openURL(url)
        }
//        self.extensionContext?.completeRequest(returningItems: nil)
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
