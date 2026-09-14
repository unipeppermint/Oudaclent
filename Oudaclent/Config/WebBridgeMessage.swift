import Foundation
import CoreFoundation

/// The public H5 contract accepts either an object or a JSON-encoded object.
struct WebBridgeMessage {
    enum Action: String {
        case openWindow, purchased, addtocart, addtowishlist, completeregistration
    }

    let action: Action
    let parameters: [String: Any]

    init(body: Any) throws {
        guard let envelope = body as? [String: Any],
              let name = envelope["action"] as? String,
              let action = Action(rawValue: name) else {
            throw ValidationError.invalidAction
        }
        self.action = action
        if let object = envelope["params"] as? [String: Any] {
            parameters = object
        } else if let string = envelope["params"] as? String,
                  let data = string.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            parameters = object
        } else {
            throw ValidationError.invalidParameters
        }
    }

    var externalURL: URL? {
        guard let raw = parameters["url"] as? String,
              let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        return url
    }

    func event() throws -> FacebookWebEvent {
        guard action != .openWindow else { throw ValidationError.invalidAction }
        // Registration need not have a price. If either monetary field is supplied,
        // validate the complete pair just as for the other events.
        if action == .completeregistration,
           parameters["value"] == nil, parameters["currency"] == nil {
            return FacebookWebEvent(action: action, value: nil, currency: nil)
        }
        guard let number = parameters["value"] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite, number.doubleValue >= 0,
              let rawCurrency = parameters["currency"] as? String else {
            throw ValidationError.invalidAmount
        }
        let currency = rawCurrency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard Locale.isoCurrencyCodes.contains(currency) else { throw ValidationError.invalidCurrency }
        return FacebookWebEvent(action: action, value: number.doubleValue, currency: currency)
    }

    enum ValidationError: String, Error {
        case invalidAction, invalidParameters, invalidAmount, invalidCurrency
    }
}

struct FacebookWebEvent {
    let action: WebBridgeMessage.Action
    let value: Double?
    let currency: String?
}

enum IOSWebBridge {
    static let handlerName = "iosapp"
    static let script = """
    (function() {
        window.iosapp = {
            postMessage: function(action, params) {
                window.webkit.messageHandlers.iosapp.postMessage({action: action, params: params});
            }
        };
    })();
    """
}
