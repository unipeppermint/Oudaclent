//
//  SceneDelegate.swift
//  Oudaclent
//
//  Created by mac on 2026/9/8.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = StartupLoadingViewController()
        window.makeKeyAndVisible()
        let router = PushNotificationRouter.shared
        router.isReady = false
        router.onDestination = { [weak self] destination in self?.openPushDestination(destination) }
        if let response = connectionOptions.notificationResponse {
            PushNotificationService.shared.handleNotificationResponse(response)
        }
        loadStartupDestination()
        FacebookEventService.shared.handleOpenURLContexts(connectionOptions.urlContexts)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        FacebookEventService.shared.handleOpenURLContexts(URLContexts)
    }

    private func loadStartupDestination() {
        StartupLinkService.shared.fetchLaunchURL { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }

                switch result {
                case .success(let url):
                    self.showStartupWebView(url: url)
                case .failure:
                    if let cachedURL = StartupLinkStore.shared.lastWebViewURL {
                        self.showStartupWebView(url: cachedURL)
                    } else {
                        self.showMainApp()
                    }
                }
                PushNotificationRouter.shared.isReady = true
            }
        }
    }

    private func openPushDestination(_ destination: PushDestination) {
        if let root = window?.rootViewController, root.presentedViewController != nil {
            root.dismiss(animated: false) { [weak self] in self?.applyPushDestination(destination) }
        } else {
            applyPushDestination(destination)
        }
    }

    private func applyPushDestination(_ destination: PushDestination) {
        if let url = destination.url {
            showStartupWebView(url: url)
            return
        }
        guard let screen = destination.screen else { return }
        // Unknown game IDs must not discard the user's current screen.
        if screen == .game, let id = destination.gameID,
           !MockData.hotSlots.contains(where: { $0.id == id }) { return }
        let tabs = window?.rootViewController as? MainTabBarController ?? MainTabBarController()
        if window?.rootViewController !== tabs { window?.rootViewController = tabs }
        tabs.loadViewIfNeeded()
        switch screen {
        case .lobby: tabs.showLobby()
        case .rewards: tabs.showRewards()
        case .profile: tabs.showProfile()
        case .game:
            if let id = destination.gameID, let game = MockData.hotSlots.first(where: { $0.id == id }) {
                tabs.showGame(game)
            } else { tabs.showGame() }
        }
        (tabs.selectedViewController as? UINavigationController)?.popToRootViewController(animated: false)
    }

    private func showStartupWebView(url: URL) {
        window?.rootViewController = StartupWebViewController(url: url)
    }

    private func showMainApp() {
        window?.rootViewController = MainTabBarController()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        PushNotificationService.shared.refreshAuthorization { _ in }
        UIApplication.shared.applicationIconBadgeNumber = 0
        TrackingAuthorizationCoordinator.shared.applicationDidBecomeActive()
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
