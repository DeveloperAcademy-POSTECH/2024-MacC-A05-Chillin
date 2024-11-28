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
    @StateObject private var homeViewModel: HomeViewModel = .init(
        homeViewUseCase: DefaultHomeViewUseCase(
            paperDataRepository: PaperDataRepositoryImpl(),
            folderDataRepository: FolderDataRepositoryImpl()
        )
    )
    
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
            .environmentObject(homeViewModel)
            .onAppear {
                setSample()
            }
            .onOpenURL(perform: openUrlScheme)
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


extension AppView {
    private func setSample() {
        let isFirst = UserDefaults.standard.bool(forKey: "sample")
        
        if isFirst {
            return
        }
        
        let url = Bundle.main.url(forResource: "sample", withExtension: "json")!
        
        let layout = try! JSONDecoder().decode(PDFLayoutResponseDTO.self, from: .init(contentsOf: url))
        
        let id = homeViewModel.uploadSamplePDF()!
        UserDefaults.standard.set(id.uuidString, forKey: "sampleId")
        homeViewModel.updateIsFigureSaved(at: id, isFigureSaved: true)
        
        
        
        layout.fig.forEach {
            let _ = FigureDataRepositoryImpl().saveFigureData(for: id, with: .init(
                id: $0.id,
                head: $0.head,
                coords: $0.coords))
        }
        
        UserDefaults.standard.set(true, forKey: "sample")
    }
    
    private func openUrlScheme(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components!.queryItems!
        let manager = FileManager.default
        
        let containerURL = manager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.chillin.reazy")
        
        for item in items {
            if let containerFileURL = containerURL?.appending(path: item.value!),
               manager.fileExists(atPath: containerFileURL.path()) {
                let _ = homeViewModel.uploadPDF(url: [containerFileURL])
                
                try! manager.removeItem(at: containerFileURL)
            }
        }
    }
}
