import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

enum PushAuthorizationStatus {
    case authorized, denied, notDetermined, unavailable
}

final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()
    private let notificationCenter = UNUserNotificationCenter.current()
    private var authorizationCompletions: [(PushAuthorizationStatus) -> Void] = []
    private var isRequestingAuthorization = false
    private var tokenRequestInFlight = false
    private var tokenCacheKey = ""
    private(set) var isConfigured = false
    private(set) var fcmToken: String?

    private override init() { super.init() }

    func configure(requestPermission: Bool = true) {
        guard !isConfigured else { return }
        notificationCenter.delegate = self
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            Self.log("GoogleService-Info.plist is missing")
            return
        }
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        guard let app = FirebaseApp.app() else { return }
        tokenCacheKey = "fcmRegistrationToken.\(Bundle.main.bundleIdentifier ?? "").\(app.options.googleAppID)"
        fcmToken = UserDefaults.standard.string(forKey: tokenCacheKey)
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        isConfigured = true
        synchronizeAuthorization { _ in }
        if requestPermission { requestAuthorization { _ in } }
    }

    /// Called on every activation, including a return from system Settings.
    func refreshAuthorization(completion: @escaping (Bool) -> Void) {
        synchronizeAuthorization { status in
            completion(status == .authorized)
        }
    }

    func requestAuthorization(completion: @escaping (PushAuthorizationStatus) -> Void) {
        guard isConfigured else { completion(.unavailable); return }
        authorizationCompletions.append(completion)
        guard !isRequestingAuthorization else { return }
        isRequestingAuthorization = true
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .notDetermined else {
                    self.synchronizeAuthorization { self.finishAuthorization($0) }
                    return
                }
                self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                    if let error { Self.log("Authorization failed: \(error.localizedDescription)") }
                    DispatchQueue.main.async {
                        self.synchronizeAuthorization { self.finishAuthorization($0) }
                    }
                }
            }
        }
    }

    private func finishAuthorization(_ status: PushAuthorizationStatus) {
        isRequestingAuthorization = false
        let completions = authorizationCompletions
        authorizationCompletions.removeAll()
        completions.forEach { $0(status) }
    }

    private func synchronizeAuthorization(completion: @escaping (PushAuthorizationStatus) -> Void) {
        guard isConfigured else { completion(.unavailable); return }
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status: PushAuthorizationStatus
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral: status = .authorized
                case .notDetermined: status = .notDetermined
                default: status = .denied
                }
                if status == .authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    UIApplication.shared.unregisterForRemoteNotifications()
                }
                completion(status)
            }
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        guard isConfigured else { return }
        Messaging.messaging().apnsToken = deviceToken
        // Fetch after APNs registration. A failure is retried on the next activation/registration.
        guard !tokenRequestInFlight else { return }
        tokenRequestInFlight = true
        Messaging.messaging().token { token, error in
            DispatchQueue.main.async {
                self.tokenRequestInFlight = false
                if let error { Self.log("FCM token request failed: \(error.localizedDescription)") }
                if let token { self.storeToken(token) }
            }
        }
    }

    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        Self.log("APNs registration failed: \(error.localizedDescription)")
    }

    private func storeToken(_ token: String) {
        guard !token.isEmpty else { return }
        fcmToken = token
        UserDefaults.standard.set(token, forKey: tokenCacheKey)
        NotificationCenter.default.post(name: .didUpdateFCMToken, object: token)
        Self.log("FCM token: \(token)")
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        guard response.actionIdentifier != UNNotificationDismissActionIdentifier else { return }
        let payload = response.notification.request.content.userInfo
        PushNotificationRouter.shared.receive(payload, identifier: response.notification.request.identifier)
        NotificationCenter.default.post(name: .didReceivePushNotification, object: payload)
    }

    /// A silent refresh never opens a screen. Supported payload: {"refresh":"startup"}.
    func handleBackgroundNotification(_ payload: [AnyHashable: Any], completion: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationCenter.default.post(name: .didReceiveBackgroundPush, object: payload)
        let nested = payload["data"] as? [String: Any]
        guard (payload["refresh"] as? String ?? nested?["refresh"] as? String) == "startup" else {
            completion(.noData)
            return
        }
        StartupLinkService.shared.fetchLaunchURL { result in
            switch result {
            case .success(let url):
                let changed = StartupLinkStore.shared.lastWebViewURL != url
                if changed { StartupLinkStore.shared.save(url: url) }
                completion(changed ? .newData : .noData)
            case .failure: completion(.failed)
            }
        }
    }

    private static func log(_ text: String) {
#if DEBUG
        print("[Push] \(text)")
#endif
    }
}

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        DispatchQueue.main.async { self.storeToken(fcmToken) }
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.handleNotificationResponse(response)
            completionHandler()
        }
    }
}

extension Notification.Name {
    static let didUpdateFCMToken = Notification.Name("didUpdateFCMToken")
    static let didReceivePushNotification = Notification.Name("didReceivePushNotification")
    static let didReceiveBackgroundPush = Notification.Name("didReceiveBackgroundPush")
}
