import UIKit
import WebKit

final class StartupWebViewController: UIViewController {
    private enum ScriptBridge {
        static let openSafari = "openSafari"
        static let open = "open"
        static let all = [openSafari, open, IOSWebBridge.handlerName]
    }

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorStack = UIStackView()
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
        contentController.addUserScript(WKUserScript(
            source: IOSWebBridge.script,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
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
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        let message = UILabel()
        message.text = "Unable to load this page. Check your connection and try again."
        message.numberOfLines = 0
        message.textAlignment = .center
        let retry = UIButton(type: .system)
        retry.setTitle("Retry", for: .normal)
        retry.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.errorStack.isHidden = true
            self.webView.load(URLRequest(url: self.webView.url ?? self.initialURL))
        }, for: .touchUpInside)
        errorStack.axis = .vertical
        errorStack.spacing = 16
        errorStack.addArrangedSubview(message)
        errorStack.addArrangedSubview(retry)
        errorStack.backgroundColor = .systemBackground
        errorStack.isHidden = true
        errorStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorStack)
        NSLayoutConstraint.activate([
            errorStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func saveCurrentURL() {
        guard AppConfig.startupURLOverride == nil, let url = webView.url else { return }
        StartupLinkStore.shared.save(url: url)
    }

    private func openExternalBrowser(with body: Any) {
        guard let url = externalWebURL(from: body) else {
#if DEBUG
            print("[StartupWebViewController] invalid external URL message")
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
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        errorStack.isHidden = true
        loadingIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showLoadError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showLoadError(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadingIndicator.stopAnimating()
        errorStack.isHidden = false
    }

    private func showLoadError(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        loadingIndicator.stopAnimating()
        errorStack.isHidden = false
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        saveCurrentURL()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        errorStack.isHidden = true
        saveCurrentURL()
    }
}

extension StartupWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard presentedViewController == nil else { completionHandler(); return }
        let alert = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard presentedViewController == nil else { completionHandler(false); return }
        let alert = UIAlertController(title: webView.url?.host, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        guard presentedViewController == nil else { completionHandler(nil); return }
        let alert = UIAlertController(title: webView.url?.host, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
            completionHandler(alert?.textFields?.first?.text)
        })
        present(alert, animated: true)
    }

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
        guard message.frameInfo.isMainFrame else { return }
        switch message.name {
        case IOSWebBridge.handlerName:
            do {
                let request = try WebBridgeMessage(body: message.body)
                if request.action == .openWindow {
                    guard let url = request.externalURL else {
                        FacebookEventService.debugLog("Rejected invalid openWindow URL")
                        return
                    }
                    UIApplication.shared.open(url, options: [:]) { success in
                        if !success { FacebookEventService.debugLog("External browser open failed") }
                    }
                } else {
                    FacebookEventService.shared.log(try request.event())
                }
            } catch {
                FacebookEventService.debugLog("Rejected bridge message: \(error)")
            }
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
