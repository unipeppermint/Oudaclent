import UIKit
import AppTrackingTransparency

/// Serializes the first ATT and notification prompts; revisits ATT after Settings changes.
final class TrackingAuthorizationCoordinator {
    static let shared = TrackingAuthorizationCoordinator()
    private var requestInFlight = false
    private var scheduled = false
    private var notificationsRequested = false

    private init() {}

    func applicationDidBecomeActive() {
        guard !scheduled, !requestInFlight else { return }
        scheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.scheduled = false
            self.advance()
        }
    }

    private func advance() {
        guard UIApplication.shared.applicationState == .active, !requestInFlight else { return }
        FacebookEventService.shared.updateTrackingAuthorization()
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            requestInFlight = true
            ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.requestInFlight = false
                    FacebookEventService.shared.updateTrackingAuthorization()
                    // A transient notDetermined result is retried on the next activation.
                    if ATTrackingManager.trackingAuthorizationStatus != .notDetermined {
                        self.applicationDidBecomeActive()
                    }
                }
            }
        } else if !notificationsRequested {
            notificationsRequested = true
            PushNotificationService.shared.requestAuthorization { _ in }
        }
    }
}
