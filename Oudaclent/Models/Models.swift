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

    var maximumMultiplier: Int { symbolSet.map(\.payoutMultiplier).max() ?? 0 }

    var payTable: [PayTableEntry] {
        var rows = symbolSet.map {
            PayTableEntry(combination: Array(repeating: $0, count: reels), multiplier: $0.payoutMultiplier)
        }
        if [.seven, .star, .diamond].allSatisfy({ symbolSet.contains($0) }) {
            rows.append(PayTableEntry(combination: [.seven, .star, .diamond], multiplier: 3))
        }
        return rows
    }
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

    var payoutMultiplier: Int {
        switch self {
        case .seven: return 100
        case .star: return 25
        case .diamond: return 15
        case .bar: return 10
        case .cherry: return 5
        }
    }

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
    var gemReward: Int = 0
}

enum RewardKind: String, Codable {
    case spinPerk
    case bonusTicket
    case cosmetic
}

enum RewardCurrency: String, Codable {
    case points
    case gems

    var title: String {
        switch self {
        case .points: return "POINTS"
        case .gems: return "GEMS"
        }
    }

    var symbol: String {
        switch self {
        case .points: return "●"
        case .gems: return "♦"
        }
    }
}

struct RewardItem: Identifiable {
    var id: String
    var title: String
    var description: String
    var iconName: String
    var cost: Int
    var currency: RewardCurrency = .points
    var kind: RewardKind
    var accentColor: UIColor

    var categoryTitle: String {
        switch kind {
        case .spinPerk: return "SPIN PERK"
        case .bonusTicket: return "BONUS TICKET"
        case .cosmetic: return "PROFILE STYLE"
        }
    }
}

extension Notification.Name {
    static let didUpdateRewards = Notification.Name("didUpdateRewards")
    static let didUpdateWallet = Notification.Name("didUpdateWallet")
    static let didUpdateEngagement = Notification.Name("didUpdateEngagement")
    static let didUpdateAchievements = Notification.Name("didUpdateAchievements")
}

enum AppCurrency: String {
    case coins
    case gems
}

final class AppCurrencyStore {
    static let shared = AppCurrencyStore()

    private enum Key {
        static let coins = "walletCoins"
        static let gems = "walletGems"
    }

    private let defaults = UserDefaults.standard

    var coins: Int {
        get {
            defaults.object(forKey: Key.coins) as? Int ?? MockData.user.coins
        }
        set {
            defaults.set(max(0, newValue), forKey: Key.coins)
            notifyUpdate()
        }
    }

    var gems: Int {
        get {
            defaults.object(forKey: Key.gems) as? Int ?? MockData.user.gems
        }
        set {
            defaults.set(max(0, newValue), forKey: Key.gems)
            notifyUpdate()
        }
    }

    func balance(for currency: AppCurrency) -> Int {
        switch currency {
        case .coins: return coins
        case .gems: return gems
        }
    }

    @discardableResult
    func add(_ amount: Int, to currency: AppCurrency) -> Int {
        guard amount > 0 else { return balance(for: currency) }
        switch currency {
        case .coins:
            coins += amount
        case .gems:
            gems += amount
        }
        return balance(for: currency)
    }

    @discardableResult
    func spend(_ amount: Int, from currency: AppCurrency) -> Bool {
        guard amount >= 0, balance(for: currency) >= amount else { return false }
        switch currency {
        case .coins:
            coins -= amount
        case .gems:
            gems -= amount
        }
        return true
    }

    private func notifyUpdate() {
        NotificationCenter.default.post(name: .didUpdateWallet, object: nil)
    }
}

final class AppRewardsStore {
    static let shared = AppRewardsStore()

    private enum Key {
        static let points = "rewardPoints"
        static let activeRewardIDs = "activeRewardIDs"
        static let ownedRewardIDs = "ownedRewardIDs"
    }

    private let defaults = UserDefaults.standard

    var points: Int {
        get {
            defaults.object(forKey: Key.points) as? Int ?? MockData.user.points
        }
        set {
            defaults.set(max(0, newValue), forKey: Key.points)
            NotificationCenter.default.post(name: .didUpdateRewards, object: nil)
        }
    }

    var activeRewards: [RewardItem] {
        let ids = activeRewardIDs
        return MockData.rewardsCatalog.filter { ids.contains($0.id) }
    }

    func canRedeem(_ item: RewardItem) -> Bool {
        balance(for: item.currency) >= item.cost && !isRedeemed(item)
    }

    func balance(for currency: RewardCurrency) -> Int {
        switch currency {
        case .points: return points
        case .gems: return AppCurrencyStore.shared.gems
        }
    }

    func isRedeemed(_ item: RewardItem) -> Bool {
        switch item.kind {
        case .cosmetic:
            return ownedRewardIDs.contains(item.id)
        case .spinPerk, .bonusTicket:
            return activeRewardIDs.contains(item.id)
        }
    }

    @discardableResult
    func redeem(_ item: RewardItem) -> Bool {
        guard canRedeem(item) else { return false }
        switch item.currency {
        case .points:
            points -= item.cost
        case .gems:
            guard AppCurrencyStore.shared.spend(item.cost, from: .gems) else { return false }
        }
        if item.kind == .cosmetic {
            var ids = ownedRewardIDs
            ids.insert(item.id)
            ownedRewardIDs = ids
            defaults.set(item.id, forKey: "selectedProfileFrame")
        } else {
            var ids = activeRewardIDs
            ids.insert(item.id)
            activeRewardIDs = ids
        }
        NotificationCenter.default.post(name: .didUpdateRewards, object: nil)
        return true
    }

    var profileFrame: RewardItem? {
        let selectedID = defaults.string(forKey: "selectedProfileFrame")
        return MockData.rewardsCatalog.first { $0.kind == .cosmetic && $0.id == selectedID && ownedRewardIDs.contains($0.id) }
            ?? MockData.rewardsCatalog.last { $0.kind == .cosmetic && ownedRewardIDs.contains($0.id) }
    }

    func equipFrame(_ item: RewardItem) {
        guard item.kind == .cosmetic, ownedRewardIDs.contains(item.id) else { return }
        defaults.set(item.id, forKey: "selectedProfileFrame")
        NotificationCenter.default.post(name: .didUpdateRewards, object: nil)
    }

    func hasActiveReward(_ id: String) -> Bool {
        activeRewardIDs.contains(id)
    }

    func consumeActiveReward(_ id: String) {
        var ids = activeRewardIDs
        guard ids.remove(id) != nil else { return }
        activeRewardIDs = ids
        NotificationCenter.default.post(name: .didUpdateRewards, object: nil)
    }

    private var activeRewardIDs: Set<String> {
        get {
            Set(defaults.stringArray(forKey: Key.activeRewardIDs) ?? [])
        }
        set {
            defaults.set(Array(newValue), forKey: Key.activeRewardIDs)
        }
    }

    private var ownedRewardIDs: Set<String> {
        get {
            Set(defaults.stringArray(forKey: Key.ownedRewardIDs) ?? [])
        }
        set {
            defaults.set(Array(newValue), forKey: Key.ownedRewardIDs)
        }
    }
}

struct CheckInResult {
    let streak: Int
    let coins: Int
    let gems: Int
}

final class AppEngagementStore {
    static let shared = AppEngagementStore()

    private enum Key {
        static let lastCheckInDate = "lastCheckInDate"
        static let checkInStreak = "checkInStreak"
    }

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    var streak: Int {
        defaults.object(forKey: Key.checkInStreak) as? Int ?? 0
    }

    var canCheckIn: Bool {
        guard let lastDate = defaults.object(forKey: Key.lastCheckInDate) as? Date else {
            return true
        }
        return calendar.startOfDay(for: lastDate) < today
    }

    var nextCheckInReward: (coins: Int, gems: Int, streak: Int) {
        let nextStreak = canCheckIn ? nextStreakValue : streak
        let day = ((max(1, nextStreak) - 1) % 7) + 1
        return (coins: coinsForCheckInDay(day), gems: gemsForCheckInDay(day), streak: nextStreak)
    }

    @discardableResult
    func checkIn() -> CheckInResult? {
        guard canCheckIn else { return nil }

        let nextStreak = nextStreakValue
        let day = ((max(1, nextStreak) - 1) % 7) + 1
        let coins = coinsForCheckInDay(day)
        let gems = gemsForCheckInDay(day)

        defaults.set(today, forKey: Key.lastCheckInDate)
        defaults.set(nextStreak, forKey: Key.checkInStreak)
        AppCurrencyStore.shared.add(coins, to: .coins)
        AppCurrencyStore.shared.add(gems, to: .gems)
        NotificationCenter.default.post(name: .didUpdateEngagement, object: nil)
        return CheckInResult(streak: nextStreak, coins: coins, gems: gems)
    }

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var nextStreakValue: Int {
        guard let lastDate = defaults.object(forKey: Key.lastCheckInDate) as? Date else {
            return max(1, streak + 1)
        }
        let daysSinceLastCheckIn = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastDate),
            to: today
        ).day ?? 0
        return daysSinceLastCheckIn == 1 ? streak + 1 : 1
    }

    private func coinsForCheckInDay(_ day: Int) -> Int {
        day == 7 ? 1_000 : 250 + (day * 100)
    }

    private func gemsForCheckInDay(_ day: Int) -> Int {
        switch day {
        case 3: return 2
        case 7: return 5
        default: return 1
        }
    }
}

final class AppAchievementStore {
    static let shared = AppAchievementStore()

    private let defaults = UserDefaults.standard
    private enum Key {
        static let claimed = "claimedAchievementRewards"
        static let winStreak = "achievementWinStreak"
    }

    var currentWinStreak: Int {
        defaults.object(forKey: Key.winStreak) as? Int ?? 0
    }

    var achievements: [Achievement] {
        let claimed = Set(defaults.stringArray(forKey: Key.claimed) ?? [])
        return MockData.achievements.map { achievement in
            var updated = achievement
            updated.unlocked = claimed.contains(achievement.title)
            updated.currentProgress = updated.unlocked ? achievement.totalProgress
                : (achievement.title == "First Jackpot" ? 0 : min(currentWinStreak, achievement.totalProgress))
            return updated
        }
    }

    @discardableResult
    func recordSpin(win: Int, hitJackpot: Bool) -> Int {
        let nextStreak = win > 0 ? currentWinStreak + 1 : 0
        defaults.set(nextStreak, forKey: Key.winStreak)

        var gemsEarned = 0
        if hitJackpot {
            var jackpot = MockData.achievements[0]
            jackpot.unlocked = true
            gemsEarned += claim(jackpot)
        }
        for achievement in MockData.achievements where achievement.title != "First Jackpot" {
            guard nextStreak >= achievement.totalProgress else { continue }
            var unlockedAchievement = achievement
            unlockedAchievement.unlocked = true
            unlockedAchievement.currentProgress = achievement.totalProgress
            gemsEarned += claim(unlockedAchievement)
        }
        NotificationCenter.default.post(name: .didUpdateAchievements, object: nil)
        return gemsEarned
    }

    @discardableResult
    func claim(_ achievement: Achievement) -> Int {
        guard achievement.unlocked, achievement.gemReward > 0 else { return 0 }
        var claimed = Set(defaults.stringArray(forKey: Key.claimed) ?? [])
        guard claimed.insert(achievement.title).inserted else { return 0 }
        defaults.set(Array(claimed), forKey: Key.claimed)
        AppCurrencyStore.shared.add(achievement.gemReward, to: .gems)
        NotificationCenter.default.post(name: .didUpdateAchievements, object: nil)
        return achievement.gemReward
    }
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
    case rewards = "REWARDS"
    case me = "ME"

    var iconName: String {
        switch self {
        case .lobby: return "house"
        case .game: return "gamecontroller"
        case .rewards: return "gift"
        case .me: return "person"
        }
    }

    var iconNameSelected: String {
        switch self {
        case .lobby: return "house.fill"
        case .game: return "gamecontroller.fill"
        case .rewards: return "gift.fill"
        case .me: return "person.fill"
        }
    }
}

enum MockData {
    static let user = User(id: "lucky-player")

    static let hotSlots: [SlotGame] = [
        SlotGame(
            id: "lucky7",
            title: "Lucky 7",
            subtitle: "3 Reels · Middle Row",
            theme: .classic,
            reels: 3,
            paylines: 1,
            minBet: 100,
            jackpotPool: 1_000_000,
            features: [
                GameFeature(iconName: "crown.fill", title: "JACKPOT", description: "Match three 7s on the middle row for x100."),
                GameFeature(iconName: "arrow.triangle.2.circlepath", title: "Free Spins", description: "Redeem a ticket in Rewards for a free spin."),
                GameFeature(iconName: "bolt.fill", title: "Pay Table", description: "See the pay table for each symbol.")
            ],
            symbolSet: [.seven, .star, .diamond, .bar, .cherry]
        ),
        SlotGame(
            id: "sweetCandy",
            title: "Sweet Candy",
            subtitle: "5 Reels · Middle Row",
            theme: .candy,
            reels: 5,
            paylines: 1,
            minBet: 50,
            jackpotPool: 500_000,
            features: [
                GameFeature(iconName: "sparkles", title: "Matching Symbols", description: "Match five symbols on the middle row."),
                GameFeature(iconName: "gift.fill", title: "Daily Check-in", description: "Collect your daily reward in the lobby.")
            ],
            symbolSet: [.star, .cherry, .diamond]
        ),
        SlotGame(
            id: "treasureHunter",
            title: "Treasure Hunter",
            subtitle: "5 Reels · Treasure Bonus",
            theme: .treasure,
            reels: 5,
            paylines: 1,
            minBet: 200,
            jackpotPool: 2_000_000,
            features: [
                GameFeature(iconName: "map.fill", title: "Pick Bonus", description: "Choose a chest and reveal a prize"),
                GameFeature(iconName: "shield.lefthalf.filled", title: "Coin Shield", description: "Refund half the cost of a losing paid spin.")
            ],
            symbolSet: [.seven, .star, .diamond, .bar]
        )
    ]

    static let achievements: [Achievement] = [
        Achievement(title: "First Jackpot", description: "Hit your first jackpot", iconName: "trophy.fill", currentProgress: 1, totalProgress: 1, unlocked: true, gemReward: 10),
        Achievement(title: "10 Win Streak", description: "Win 10 rounds in a row", iconName: "flame.fill", currentProgress: 7, totalProgress: 10, unlocked: false, gemReward: 15),
        Achievement(title: "100 Win Streak", description: "Win 100 rounds in a row", iconName: "crown.fill", currentProgress: 12, totalProgress: 100, unlocked: false, gemReward: 40)
    ]

    static let rewardsCatalog: [RewardItem] = [
        RewardItem(
            id: "freeSpinTicket",
            title: "Free Spin Ticket",
            description: "Your next spin costs no coins.",
            iconName: "ticket.fill",
            cost: 600,
            currency: .points,
            kind: .bonusTicket,
            accentColor: .brandPink
        ),
        RewardItem(
            id: "doublePointsBoost",
            title: "Double Points Boost",
            description: "Double points from your next spin.",
            iconName: "bolt.fill",
            cost: 300,
            currency: .points,
            kind: .spinPerk,
            accentColor: .brandGold
        ),
        RewardItem(
            id: "safeBetShield",
            title: "Coin Shield",
            description: "Return 50% of the coins spent if your next spin has no win.",
            iconName: "shield.lefthalf.filled",
            cost: 800,
            currency: .points,
            kind: .spinPerk,
            accentColor: .accentCyan
        ),
        RewardItem(
            id: "luckyStart",
            title: "Lucky Start",
            description: "Improve the win chance on your next spin.",
            iconName: "sparkles",
            cost: 500,
            currency: .points,
            kind: .spinPerk,
            accentColor: .brandPurple
        ),
        RewardItem(
            id: "bonusPickTicket",
            title: "Bonus Pick Ticket",
            description: "Open another chest after your current pick.",
            iconName: "gift.fill",
            cost: 1_000,
            currency: .points,
            kind: .bonusTicket,
            accentColor: .accentOrange
        ),
        RewardItem(
            id: "goldCrownFrame",
            title: "Gold Crown Frame",
            description: "Add a gold frame to your profile.",
            iconName: "crown.fill",
            cost: 80,
            currency: .gems,
            kind: .cosmetic,
            accentColor: .brandGold
        ),
        RewardItem(
            id: "premiumFreeSpin",
            title: "Premium Free Spin",
            description: "Your next spin costs no coins and earns a gem bonus.",
            iconName: "sparkles",
            cost: 20,
            currency: .gems,
            kind: .bonusTicket,
            accentColor: .accentCyan
        ),
        RewardItem(
            id: "treasureReroll",
            title: "Treasure Reroll",
            description: "Reroll all three treasure chests once.",
            iconName: "arrow.triangle.2.circlepath",
            cost: 5,
            currency: .gems,
            kind: .bonusTicket,
            accentColor: .accentCyan
        ),
        RewardItem(
            id: "doubleTreasure",
            title: "Double Treasure",
            description: "Double the coins from your next treasure pick.",
            iconName: "bolt.fill",
            cost: 12,
            currency: .gems,
            kind: .spinPerk,
            accentColor: .accentOrange
        ),
        RewardItem(
            id: "diamondProfileFrame",
            title: "Diamond Profile Frame",
            description: "Add a diamond frame to your profile.",
            iconName: "diamond.fill",
            cost: 150,
            currency: .gems,
            kind: .cosmetic,
            accentColor: .brandPurple
        )
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

    static func points(_ value: Int) -> String {
        "● \(integer.string(from: NSNumber(value: value)) ?? "\(value)")"
    }

    static func gems(_ value: Int) -> String {
        "♦ \(integer.string(from: NSNumber(value: value)) ?? "\(value)")"
    }
}
