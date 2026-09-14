import Foundation
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

enum PushAuthorizationStatus {
    case authorized
    case denied
    case notDetermined
    case unavailable
}

final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private(set) var isConfigured = false
    private(set) var fcmToken: String? {
        didSet {
            UserDefaults.standard.set(fcmToken, forKey: "fcmRegistrationToken")
            NotificationCenter.default.post(
                name: .didUpdateFCMToken,
                object: fcmToken
            )
        }
    }

    private override init() {
        super.init()
    }

    func configure(requestPermission: Bool = true) {
        guard !isConfigured else { return }

        notificationCenter.delegate = self

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("[Push] GoogleService-Info.plist is missing; Firebase Messaging is disabled.")
            return
        }

        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        isConfigured = true

        guard requestPermission else { return }
        requestAuthorization { status in
            if status == .denied {
                print("[Push] Notification permission is denied.")
            }
        }
    }

    func setEnabled(_ enabled: Bool, completion: @escaping (PushAuthorizationStatus) -> Void) {
        if !enabled {
            var settings = AppSettingsStore.shared.settings
            settings.notificationsEnabled = false
            AppSettingsStore.shared.settings = settings
            UIApplication.shared.unregisterForRemoteNotifications()
            completion(.denied)
            return
        }
        requestAuthorization { status in
            DispatchQueue.main.async {
                var settings = AppSettingsStore.shared.settings
                settings.notificationsEnabled = status == .authorized
                AppSettingsStore.shared.settings = settings
                if status == .authorized { self.registerForRemoteNotifications() }
                completion(status)
            }
        }
    }

    func refreshAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            let allowed = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
            DispatchQueue.main.async {
                completion(self.isConfigured && allowed && AppSettingsStore.shared.settings.notificationsEnabled)
            }
        }
    }

    func requestAuthorization(completion: @escaping (PushAuthorizationStatus) -> Void) {
        guard isConfigured else {
            completion(.unavailable)
            return
        }

        notificationCenter.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self?.registerForRemoteNotifications()
                completion(.authorized)
            case .notDetermined:
                self?.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error {
                        print("[Push] Authorization failed: \(error.localizedDescription)")
                        completion(.denied)
                        return
                    }

                    guard granted else {
                        completion(.denied)
                        return
                    }

                    self?.registerForRemoteNotifications()
                    completion(.authorized)
                }
            case .denied:
                completion(.denied)
            @unknown default:
                completion(.denied)
            }
        }
    }

    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        guard isConfigured else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        print("[Push] APNs registration failed: \(error.localizedDescription)")
    }

    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            // No saved preference means this is the first successful authorization.
            if UserDefaults.standard.object(forKey: "notificationsEnabled") == nil {
                var settings = AppSettingsStore.shared.settings
                settings.notificationsEnabled = true
                AppSettingsStore.shared.settings = settings
            }
            guard AppSettingsStore.shared.settings.notificationsEnabled else { return }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        print("[Push] FCM registration token: \(fcmToken ?? "<nil>")")
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(AppSettingsStore.shared.settings.notificationsEnabled ? [.banner, .sound, .badge] : [])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationCenter.default.post(
            name: .didReceivePushNotification,
            object: response.notification.request.content.userInfo
        )
        completionHandler()
    }
}

extension Notification.Name {
    static let didUpdateFCMToken = Notification.Name("didUpdateFCMToken")
    static let didReceivePushNotification = Notification.Name("didReceivePushNotification")
}
