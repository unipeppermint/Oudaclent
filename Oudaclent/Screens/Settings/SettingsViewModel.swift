import Foundation

enum SettingsRow {
    case toggle(icon: String, title: String, keyPath: WritableKeyPath<AppSettings, Bool>)
    case value(icon: String, title: String, value: String)
    case action(icon: String, title: String, destructive: Bool)
    case header(String)
}

final class SettingsViewModel {
    private let store = AppSettingsStore.shared

    var settings: AppSettings {
        get { store.settings }
        set { store.settings = newValue }
    }

    var rows: [SettingsRow] {
        [
            .header("GENERAL"),
            .toggle(icon: "speaker.wave.2.fill", title: "Sound", keyPath: \.soundEnabled),
            .toggle(icon: "iphone.radiowaves.left.and.right", title: "Vibration", keyPath: \.vibrationEnabled),
            .toggle(icon: "bell.fill", title: "Notifications", keyPath: \.notificationsEnabled),
            .value(icon: "star.fill", title: "Bet Amount", value: Formatters.coins(settings.betAmount)),
            .header("SUPPORT"),
            .action(icon: "questionmark.circle.fill", title: "Help Center", destructive: false),
            .action(icon: "envelope.fill", title: "Contact Us", destructive: false),
            .action(icon: "info.circle.fill", title: "About Us", destructive: false)
        ]
    }

    func set(_ value: Bool, for keyPath: WritableKeyPath<AppSettings, Bool>) {
        var copy = settings
        copy[keyPath: keyPath] = value
        settings = copy
    }

    func setBetAmount(_ amount: Int) {
        var copy = settings
        copy.betAmount = amount
        settings = copy
    }
}
