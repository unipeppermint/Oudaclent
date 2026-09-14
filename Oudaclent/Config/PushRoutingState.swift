import Foundation

struct PushDestination: Equatable {
    enum Screen: String { case lobby, game, rewards, profile }
    let url: URL?
    let screen: Screen?
    let gameID: String?

    init?(payload: [AnyHashable: Any]) {
        var fields = payload
        if let data = payload["data"] as? [String: Any] {
            data.forEach { fields[$0.key] = $0.value }
        }
        if let value = fields["url"] as? String {
            guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
                  ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
                  let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else { return nil }
            self.url = url
            screen = nil
            gameID = nil
        } else if let value = fields["screen"] as? String, let screen = Screen(rawValue: value) {
            url = nil
            self.screen = screen
            gameID = fields["game_id"] as? String
        } else { return nil }
    }
}

/// Retains a cold-start route until the initial destination has finished loading.
final class PendingPushRoute {
    private(set) var destination: PushDestination?
    private var handledIDs: [String] = []

    func receive(payload: [AnyHashable: Any], identifier: String?) {
        guard let route = PushDestination(payload: payload) else { return }
        if let identifier, !identifier.isEmpty {
            guard !handledIDs.contains(identifier) else { return }
            handledIDs.append(identifier)
            if handledIDs.count > 32 { handledIDs.removeFirst() }
        }
        destination = route
    }

    func take() -> PushDestination? {
        defer { destination = nil }
        return destination
    }
}
