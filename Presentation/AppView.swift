//
//  ReazyApp.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI
import FirebaseCore

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
    
    @State private var isUpdateAlertPresented: Bool = false
    
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
            .task {
                self.homeViewModel.setSample()
                await checkAppVersion()
            }
            .onOpenURL(perform: openUrlScheme)
            .alert("Reazy의 최신 버전을 확인해보세요!", isPresented: $isUpdateAlertPresented) {
                Button("취소", role: .cancel, action: {})
                Button("업데이트", role: .none, action: {})
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // for Google Analytics
        FirebaseApp.configure()
        
        // 전체 Tint Color 설정
        UIView.appearance().tintColor = UIColor.primary1

        return true
    }
}


extension AppView {
    
    private func openUrlScheme(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components!.queryItems!
        let manager = FileManager.default
        
        let containerURL = manager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.chillin.reazy")
        
        for item in items {
            if let containerFileURL = containerURL?.appending(path: item.value!),
               let _ = try? Data(contentsOf: containerFileURL) {
                let _ = homeViewModel.uploadPDF(url: [containerFileURL])
                
                try! manager.removeItem(at: containerFileURL)
            }
        }
    }
    
    private func checkAppVersion() async {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                as? String else { return }
        
        let itunesURL = URL(string: "https://itunes.apple.com/kr/lookup?bundleId=com.chillin.reazy")!
        
        if let (data, _) = try? await URLSession.shared.data(from: itunesURL) {
            guard let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  !results.isEmpty
            else { return }
            
            if let appStoreVersion = results[0]["version"] as? String {
                if currentVersion == appStoreVersion {
                    print("Current Version: \(currentVersion), App Store Version: \(appStoreVersion)")
                    self.isUpdateAlertPresented.toggle()
                }
            }
        }
    }
}
