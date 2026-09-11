import Foundation

enum AppConfig {
    static let loginURL = URL(string: "https://pfhcdyh.top/v2/api/user/login")!
    static let loginParameters = ["username": "com.cwcl.SnackGuardians"]
    static let requestTimeout: TimeInterval = 5
}

final class StartupLinkStore {
    static let shared = StartupLinkStore()

    private enum Key {
        static let lastWebViewURL = "lastWebViewURL"
    }

    private let defaults = UserDefaults.standard

    var lastWebViewURL: URL? {
        guard let value = defaults.string(forKey: Key.lastWebViewURL) else {
            return nil
        }
        return Self.validWebURL(from: value)
    }

    func save(url: URL) {
        guard let validURL = Self.validWebURL(from: url.absoluteString) else {
            return
        }
        defaults.set(validURL.absoluteString, forKey: Key.lastWebViewURL)
    }

    private static func validWebURL(from value: String) -> URL? {
        guard
            let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return nil
        }
        return url
    }
}
