import Alamofire
import Foundation

enum StartupLinkError: LocalizedError {
    case missingLaunchURL

    var errorDescription: String? {
        switch self {
        case .missingLaunchURL:
            return "The login response did not contain a valid launch URL."
        }
    }
}

final class StartupLinkService {
    static let shared = StartupLinkService()

    private let session: Session

    private init() {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = AppConfig.requestTimeout
        configuration.timeoutIntervalForResource = AppConfig.requestTimeout
        session = Session(configuration: configuration)
    }

    func fetchLaunchURL(completion: @escaping (Result<URL, Error>) -> Void) {
        session.request(
            AppConfig.loginURL,
            method: .post,
            parameters: AppConfig.loginParameters,
            encoding: URLEncoding.httpBody
        )
        .validate(statusCode: 200..<300)
        .responseData { response in
            Self.log("login status code: \(response.response?.statusCode ?? -1)")
            switch response.result {
            case .failure(let error):
                Self.log("login request failed: \(error.localizedDescription)")
                completion(.failure(error))
            case .success(let data):
                Self.logResponse(data)
                guard
                    let object = try? JSONSerialization.jsonObject(with: data),
                    let url = Self.extractLaunchURL(from: object)
                else {
                    Self.log("launch URL parse failed")
                    completion(.failure(StartupLinkError.missingLaunchURL))
                    return
                }
                Self.log("launch URL parsed: \(url.absoluteString)")
                completion(.success(url))
            }
        }
    }

    private static let launchURLKeys = [
        "launch_url",
        "launchUrl",
        "startup_url",
        "startupUrl",
        "start_url",
        "startUrl",
        "launch_link",
        "launchLink",
        "redirect_url",
        "redirectUrl",
        "web_url",
        "webUrl",
        "jump_url",
        "jumpUrl",
        "open_url",
        "openUrl",
        "target_url",
        "targetUrl",
        "h5_url",
        "h5Url",
        "path",
        "launch",
        "startup",
        "url",
        "link",
        "result",
        "response",
        "payload"
    ]

    private static func extractLaunchURL(from value: Any) -> URL? {
        if let string = value as? String {
            return validWebURL(from: string)
        }

        if let dictionary = value as? [String: Any] {
            for key in launchURLKeys {
                if let candidate = dictionary[key], let url = extractLaunchURL(from: candidate) {
                    return url
                }
            }

            if let data = dictionary["data"], let url = extractLaunchURL(from: data) {
                return url
            }

            for candidate in dictionary.values {
                if let url = extractLaunchURL(from: candidate) {
                    return url
                }
            }
            return nil
        }

        if let array = value as? [Any] {
            for item in array {
                if let url = extractLaunchURL(from: item) {
                    return url
                }
            }
        }

        return nil
    }

    private static func validWebURL(from value: String) -> URL? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let url = URL(string: trimmedValue),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return firstWebURL(in: trimmedValue)
        }
        return url
    }

    private static func firstWebURL(in value: String) -> URL? {
        let pattern = #"https?://[^\s\]\)"']+"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = expression.firstMatch(in: value, range: range),
              let urlRange = Range(match.range, in: value) else {
            return nil
        }

        let candidate = String(value[urlRange]).trimmingCharacters(in: CharacterSet(charactersIn: ".,;"))
        guard
            let url = URL(string: candidate),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            return nil
        }
        return url
    }

    private static func logResponse(_ data: Data) {
#if DEBUG
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8 response>"
        log("login response: \(body)")
#endif
    }

    private static func log(_ message: String) {
#if DEBUG
        print("[StartupLinkService] \(message)")
#endif
    }
}
