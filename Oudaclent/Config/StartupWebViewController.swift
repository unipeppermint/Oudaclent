import UIKit
import WebKit

final class StartupWebViewController: UIViewController {
    private enum ScriptBridge {
        static let openSafari = "openSafari"
        static let open = "open"
        static let all = [openSafari, open]
    }

    private let initialURL: URL
    private var configuredUserContentController: WKUserContentController?
    private lazy var webView: WKWebView = {
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true

        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences = webpagePreferences
        configuration.preferences = preferences

        let contentController = WKUserContentController()
        let messageHandler = WeakWebScriptMessageHandler(target: self)
        ScriptBridge.all.forEach { contentController.add(messageHandler, name: $0) }
        configuration.userContentController = contentController
        configuredUserContentController = contentController

        return WKWebView(frame: .zero, configuration: configuration)
    }()

    init(url: URL) {
        initialURL = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        webView.load(URLRequest(url: initialURL))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    private func configureView() {
        view.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func saveCurrentURL() {
        guard let url = webView.url else { return }
        StartupLinkStore.shared.save(url: url)
    }

    private func openExternalBrowser(with body: Any) {
        guard let url = externalWebURL(from: body) else {
#if DEBUG
            print("[StartupWebViewController] invalid external URL message: \(body)")
#endif
            return
        }
        UIApplication.shared.open(url)
    }

    private func externalWebURL(from body: Any) -> URL? {
        if let urlString = body as? String {
            return normalizedExternalWebURL(from: urlString)
        }

        if let payload = body as? [String: Any] {
            return ["url", "href", "link", "target"]
                .compactMap { payload[$0] as? String }
                .compactMap { normalizedExternalWebURL(from: $0) }
                .first
        }
        return nil
    }

    private func normalizedExternalWebURL(from rawValue: String) -> URL? {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }

        if let url = URL(string: value), isExternalWebURL(url) {
            return url
        }
        if value.hasPrefix("//") {
            return URL(string: "https:\(value)").flatMap { isExternalWebURL($0) ? $0 : nil }
        }
        if value.contains(".") {
            return URL(string: "https://\(value)").flatMap { isExternalWebURL($0) ? $0 : nil }
        }
        return nil
    }

    private func isExternalWebURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), url.host?.isEmpty == false else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    deinit {
        guard let configuredUserContentController else { return }
        ScriptBridge.all.forEach {
            configuredUserContentController.removeScriptMessageHandler(forName: $0)
        }
    }
}

extension StartupWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        saveCurrentURL()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        saveCurrentURL()
    }
}

extension StartupWebViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard let url = navigationAction.request.url else { return nil }
        webView.load(URLRequest(url: url))
        return nil
    }
}

extension StartupWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case ScriptBridge.openSafari, ScriptBridge.open:
            openExternalBrowser(with: message.body)
        default:
            break
        }
    }
}

private final class WeakWebScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
