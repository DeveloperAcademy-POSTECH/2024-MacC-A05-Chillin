//
//  ReazyApp.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI

@main
struct AppView: App {
    // AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Navigation 컨트롤
    @StateObject private var navigationCoordinator: NavigationCoordinator = .init()
    
    @StateObject private var pdfFileManager: PDFFileManager = .init(paperService: .shared)
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigationCoordinator.path) {
                navigationCoordinator.build(.home)
                    .navigationDestination(for: Screen.self) { screen in
                        navigationCoordinator.build(screen)
                    }
                    .sheet(item: $navigationCoordinator.sheet) { sheet in
                        navigationCoordinator.build(sheet)
                    }
                    .fullScreenCover(item: $navigationCoordinator.fullScreenCover) { fullScreenCover in
                        navigationCoordinator.build(fullScreenCover)
                    }
            }
            .environmentObject(navigationCoordinator)
            .environmentObject(pdfFileManager)
            .onAppear {
                let url = Bundle.main.url(forResource: "sample", withExtension: "json")!
                let pdfURL = Bundle.main.url(forResource: "SamplePDF", withExtension: "pdf")
                let a = try! JSONDecoder().decode(PDFLayout.self, from: .init(contentsOf: url))
                
                try! pdfFileManager.uploadPDFFile(url: [pdfURL!])
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 전체 Tint Color 설정
        UIView.appearance().tintColor = UIColor.primary1

        return true
    }
}
