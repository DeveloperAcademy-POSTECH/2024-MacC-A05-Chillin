//
//  ReazyApp.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI
import FirebaseCore
import UIKit

@main
struct AppView: App {
    // AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Navigation 컨트롤
    @StateObject private var navigationCoordinator: NavigationCoordinator = .shared
    @StateObject private var homeViewModel: HomeViewModel = .init(
        homeViewUseCase: DefaultHomeViewUseCase(
            paperDataRepository: PaperDataRepositoryImpl(),
            folderDataRepository: FolderDataRepositoryImpl()
        ),
        migrationUseCase: DefaultICloudMigrationUseCase(
            migrationRepository: ICloudMigrationRepositoryImpl()
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
                
                #if !DEBUG
                await self.checkAppVersion()
                #endif
            }
            .onOpenURL(perform: openUrlScheme)
            .alert("Reazy의 새로운\n버전을 확인해보세요!", isPresented: $isUpdateAlertPresented) {
                Button("취소", role: .none, action: {})
                Button("업데이트", role: .cancel, action: openAppStore)
            } message: {
                Text("유저분들의 의견을 반영하여\n사용성을 개선했어요")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Google Analytics 설정
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        
        // 전체 Tint Color 설정
        UIView.appearance().tintColor = UIColor.primary1

        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // Mac 환경 감지 (Mac Catalyst 또는 Mac에서 실행되는 iPad 앱)
        let isMac: Bool = {
            #if targetEnvironment(macCatalyst)
            return true
            #else
            if #available(iOS 14.0, *) {
                return ProcessInfo.processInfo.isiOSAppOnMac
            }
            return false
            #endif
        }()
        
        if isMac {
            // Mac 환경: 최소 크기 696x464
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: 696, height: 464)
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad 환경: 화면 크기 기반 (가로 1/2) x (세로 2/3)
            let screenSize = windowScene.screen.bounds.size
            let minWidth = screenSize.width / 2
            let minHeight = screenSize.height * (2.0 / 3.0)
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: minWidth, height: minHeight)
        }
    }
}

extension AppView {
    /// 외부 앱에서 업로드 시 실행 메소드
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
    
    /// 설치된 버전과 앱스토어 버전을 비교하는 메소드
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
                if currentVersion != appStoreVersion {
                    log("🔔Current Version: \(currentVersion), App Store Version: \(appStoreVersion)")
                    self.isUpdateAlertPresented.toggle()
                }
            }
        }
    }
    
    /// 앱스토어 여는 메소드
    private func openAppStore() {
        if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/6737178157"),
           UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
        }
    }
}
