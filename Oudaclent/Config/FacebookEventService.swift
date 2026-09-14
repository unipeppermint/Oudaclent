import UIKit
import FBSDKCoreKit
import AppTrackingTransparency

final class FacebookEventService {
    static let shared = FacebookEventService()
    private var isReady = false
    private var pendingEvents: [FacebookWebEvent] = []

    private init() {}

    func configure(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Set these before initialization, including on subsequent launches.
        Settings.shared.isAutoLogAppEventsEnabled = false
        Settings.shared.isAdvertiserIDCollectionEnabled = false
        Settings.shared.isSKAdNetworkReportEnabled = true
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func handleOpenURLContexts(_ contexts: Set<UIOpenURLContext>) {
        for context in contexts {
            handleOpenURL(context.url, sourceApplication: context.options.sourceApplication,
                          annotation: context.options.annotation)
        }
    }

    @discardableResult
    func handleOpenURL(_ url: URL, sourceApplication: String?, annotation: Any? = nil) -> Bool {
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: sourceApplication,
            annotation: annotation
        )
    }

    func updateTrackingAuthorization() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        let authorized = status == .authorized
        Settings.shared.isAdvertiserIDCollectionEnabled = authorized
        Settings.shared.isEventDataUsageLimited = !authorized
        // SDK 18 reads ATT directly on iOS 17+. Older systems require this setter.
        if #available(iOS 17.0, *) {} else {
            Settings.shared.isAdvertiserTrackingEnabled = authorized
        }
        guard status != .notDetermined else { return }
        if !isReady {
            isReady = true
            Settings.shared.isAutoLogAppEventsEnabled = true
            let events = pendingEvents
            pendingEvents.removeAll()
            events.forEach(send)
        }
        if UIApplication.shared.applicationState == .active {
            AppEvents.shared.activateApp()
        }
    }

    func log(_ event: FacebookWebEvent) {
        guard isReady else {
            guard pendingEvents.count < 100 else {
                Self.debugLog("Pending event limit reached; event discarded")
                return
            }
            pendingEvents.append(event)
            Self.debugLog("Queued \(event.action.rawValue) until ATT resolves")
            return
        }
        send(event)
    }

    private func send(_ event: FacebookWebEvent) {
        let name: AppEvents.Name
        switch event.action {
        case .purchased: name = .purchased
        case .addtocart: name = .addedToCart
        case .addtowishlist: name = .addedToWishlist
        case .completeregistration: name = .completedRegistration
        case .openWindow: return
        }
        var parameters: [AppEvents.ParameterName: Any] = [:]
        if let currency = event.currency { parameters[.currency] = currency }
        if event.action == .purchased, let value = event.value, let currency = event.currency {
            AppEvents.shared.logPurchase(amount: value, currency: currency, parameters: parameters)
        } else if let value = event.value {
            AppEvents.shared.logEvent(name, valueToSum: value, parameters: parameters)
        } else {
            AppEvents.shared.logEvent(name, parameters: parameters)
        }
        Self.debugLog("Submitted \(event.action.rawValue) to SDK; verify delivery in Meta Events Manager")
#if DEBUG
        if AppConfig.facebookFlushEventsForTesting { AppEvents.shared.flush() }
#endif
    }

    static func debugLog(_ text: String) {
#if DEBUG
        print("[FacebookIntegration] \(text)")
#endif
    }
}
