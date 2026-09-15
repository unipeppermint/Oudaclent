import Foundation

enum AppConfig {
    static let supportEmail: String? = "cressidal@trademarkroofing.homes"
    static let loginURL = URL(string: "https://ayugdqzz.top/v2/api/user/login")!
    static let loginParameters = ["username": "com.mplpa.bqhyrgr"]
    // Enable only for H5 integration testing. Release always uses the startup API.
    static let useIntegrationTestURL = false
    static let integrationTestURL = URL(string: "https://spinlodge.com?c=112")!
    static let facebookFlushEventsForTesting = false

    static var startupURLOverride: URL? {
#if DEBUG
        return useIntegrationTestURL ? integrationTestURL : nil
#else
        return nil
#endif
    }

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
