import UIKit

struct User {
    let id: String
    var nickname: String = "Lucky Player"
    var avatarUrl: String?
    var level: Int = 12
    var memberTier: MemberTier = .gold
    var coins: Int = 12_580
    var gems: Int = 256
    var points: Int = 1_890
    var checkInStreak: Int = 5
}

enum MemberTier: String, Codable {
    case bronze, silver, gold, diamond
}

struct SlotGame {
    let id: String
    var title: String
    var subtitle: String
    var theme: SlotTheme
    var reels: Int
    var paylines: Int
    var minBet: Int
    var jackpotPool: Int
    var features: [GameFeature]
    var symbolSet: [SlotSymbol]
}

enum SlotTheme: String, Codable {
    case classic, candy, treasure

    var gradient: CAGradientLayer {
        switch self {
        case .classic:
            let layer = CAGradientLayer()
            layer.colors = [UIColor(hex: "#EF4444").cgColor, UIColor.brandGold.cgColor]
            layer.startPoint = CGPoint(x: 0, y: 0)
            layer.endPoint = CGPoint(x: 1, y: 1)
            return layer
        case .candy:
            return .brandGradient()
        case .treasure:
            return .goldGradient()
        }
    }

    var accent: UIColor {
        switch self {
        case .classic: return .warning
        case .candy: return .brandPink
        case .treasure: return .brandGold
        }
    }
}

struct GameFeature: Identifiable {
    let id = UUID()
    var iconName: String
    var title: String
    var description: String
}

enum SlotSymbol: String, Codable, CaseIterable {
    case seven = "7"
    case star = "★"
    case diamond = "♦"
    case bar = "BAR"
    case cherry = "🍒"

    var display: String { rawValue }

    var color: UIColor {
        switch self {
        case .seven: return .warning
        case .star: return .brandGold
        case .diamond: return .accentCyan
        case .bar: return .bgDark
        case .cherry: return .brandPink
        }
    }
}

struct PayTableEntry {
    var combination: [SlotSymbol]
    var multiplier: Int
}

struct Achievement: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    var iconName: String
    var currentProgress: Int
    var totalProgress: Int
    var unlocked: Bool
}

struct AppSettings {
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var notificationsEnabled: Bool = false
    var betAmount: Int = 100
    var language: String = "English"
}

final class AppSettingsStore {
    static let shared = AppSettingsStore()

    private enum Key {
        static let sound = "soundEnabled"
        static let vibration = "vibrationEnabled"
        static let notifications = "notificationsEnabled"
        static let bet = "betAmount"
    }

    private let defaults = UserDefaults.standard

    var settings: AppSettings {
        get {
            AppSettings(
                soundEnabled: defaults.object(forKey: Key.sound) as? Bool ?? true,
                vibrationEnabled: defaults.object(forKey: Key.vibration) as? Bool ?? true,
                notificationsEnabled: defaults.object(forKey: Key.notifications) as? Bool ?? false,
                betAmount: defaults.object(forKey: Key.bet) as? Int ?? 100,
                language: "English"
            )
        }
        set {
            defaults.set(newValue.soundEnabled, forKey: Key.sound)
            defaults.set(newValue.vibrationEnabled, forKey: Key.vibration)
            defaults.set(newValue.notificationsEnabled, forKey: Key.notifications)
            defaults.set(newValue.betAmount, forKey: Key.bet)
        }
    }
}

enum AppTab: String, CaseIterable {
    case lobby = "LOBBY"
    case game = "GAME"
    case me = "ME"
    case more = "MORE"

    var iconName: String {
        switch self {
        case .lobby: return "house"
        case .game: return "gamecontroller"
        case .me: return "person"
        case .more: return "ellipsis"
        }
    }

    var iconNameSelected: String {
        switch self {
        case .lobby: return "house.fill"
        case .game: return "gamecontroller.fill"
        case .me: return "person.fill"
        case .more: return "ellipsis.circle.fill"
        }
    }
}

enum MockData {
    static let user = User(id: "lucky-player")

    static let hotSlots: [SlotGame] = [
        SlotGame(
            id: "lucky7",
            title: "Lucky 7",
            subtitle: "Classic 3 Reels · High Payout",
            theme: .classic,
            reels: 3,
            paylines: 5,
            minBet: 100,
            jackpotPool: 1_000_000,
            features: [
                GameFeature(iconName: "crown.fill", title: "JACKPOT", description: "Three 7s wins the mega jackpot"),
                GameFeature(iconName: "arrow.triangle.2.circlepath", title: "Free Spins", description: "Trigger 10 free spins with 3 scatters"),
                GameFeature(iconName: "bolt.fill", title: "Multiplier", description: "Up to x10 multiplier chain")
            ],
            symbolSet: [.seven, .star, .diamond, .bar, .cherry]
        ),
        SlotGame(
            id: "sweetCandy",
            title: "Sweet Candy",
            subtitle: "5 Reels · 25 Paylines",
            theme: .candy,
            reels: 5,
            paylines: 25,
            minBet: 50,
            jackpotPool: 500_000,
            features: [
                GameFeature(iconName: "sparkles", title: "Candy Blast", description: "Wild sweets can clear a whole reel"),
                GameFeature(iconName: "gift.fill", title: "Daily Treat", description: "Collect a treat after every session")
            ],
            symbolSet: [.star, .cherry, .diamond]
        ),
        SlotGame(
            id: "treasureHunter",
            title: "Treasure Hunter",
            subtitle: "5 Reels · Treasure Bonus",
            theme: .treasure,
            reels: 5,
            paylines: 20,
            minBet: 200,
            jackpotPool: 2_000_000,
            features: [
                GameFeature(iconName: "map.fill", title: "Pick Bonus", description: "Choose a chest and reveal a prize"),
                GameFeature(iconName: "shield.lefthalf.filled", title: "Safe Bet", description: "Protection on selected max bets")
            ],
            symbolSet: [.seven, .star, .diamond, .bar]
        )
    ]

    static let achievements: [Achievement] = [
        Achievement(title: "First Jackpot", description: "Hit your first jackpot", iconName: "trophy.fill", currentProgress: 1, totalProgress: 1, unlocked: true),
        Achievement(title: "10 Win Streak", description: "Win 10 rounds in a row", iconName: "flame.fill", currentProgress: 7, totalProgress: 10, unlocked: false),
        Achievement(title: "100 Win Streak", description: "Win 100 rounds in a row", iconName: "crown.fill", currentProgress: 12, totalProgress: 100, unlocked: false)
    ]

    static let payTable: [PayTableEntry] = [
        PayTableEntry(combination: [.seven, .seven, .seven], multiplier: 100),
        PayTableEntry(combination: [.star, .star, .star], multiplier: 25),
        PayTableEntry(combination: [.diamond, .diamond, .diamond], multiplier: 15),
        PayTableEntry(combination: [.bar, .bar, .bar], multiplier: 10),
        PayTableEntry(combination: [.cherry, .cherry, .cherry], multiplier: 5),
        PayTableEntry(combination: [.seven, .star, .diamond], multiplier: 3)
    ]
}

enum Formatters {
    static let integer: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    static func coins(_ value: Int) -> String {
        "★ \(integer.string(from: NSNumber(value: value)) ?? "\(value)")"
    }
}
