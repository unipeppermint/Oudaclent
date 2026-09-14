import UIKit

final class PushNotificationRouter {
    static let shared = PushNotificationRouter()
    private let pending = PendingPushRoute()
    var onDestination: ((PushDestination) -> Void)?
    var isReady = false {
        didSet { deliverIfReady() }
    }

    func receive(_ payload: [AnyHashable: Any], identifier: String?) {
        let id = payload["gcm.message_id"] as? String ?? identifier
        pending.receive(payload: payload, identifier: id)
        deliverIfReady()
    }

    private func deliverIfReady() {
        guard isReady, let handler = onDestination, let destination = pending.take() else { return }
        handler(destination)
    }
}
