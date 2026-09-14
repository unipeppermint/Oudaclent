import Foundation

extension Notification.Name {
    static let didFinishSpin = Notification.Name("didFinishSpin")
}

struct SpinOutcome {
    let result: [[SlotSymbol]]
    let win: Int
    let jackpot: Int
    let pointsEarned: Int
    let gemsEarned: Int
    let rewardMessage: String?
}

final class GameViewModel {
    let game: SlotGame
    private(set) var coins: Int
    private(set) var jackpot: Int
    var bet: Int
    private let wallet = AppCurrencyStore.shared

    init(game: SlotGame, user: User = MockData.user) {
        self.game = game
        self.coins = wallet.coins
        self.jackpot = game.jackpotPool
        self.bet = max(game.minBet, AppSettingsStore.shared.settings.betAmount)
    }

    func refreshBalances() {
        coins = wallet.coins
    }

    func spin() -> SpinOutcome? {
        let rewardsStore = AppRewardsStore.shared
        let usesFreeSpin = rewardsStore.hasActiveReward("freeSpinTicket")
        let usesPremiumFreeSpin = !usesFreeSpin && rewardsStore.hasActiveReward("premiumFreeSpin")
        guard usesFreeSpin || usesPremiumFreeSpin || wallet.coins >= bet else { return nil }
        if usesFreeSpin {
            rewardsStore.consumeActiveReward("freeSpinTicket")
        } else if usesPremiumFreeSpin {
            rewardsStore.consumeActiveReward("premiumFreeSpin")
        } else {
            guard wallet.spend(bet, from: .coins) else { return nil }
        }
        coins = wallet.coins
        jackpot += Int(Double(bet) * 0.08)

        var result = (0..<game.reels).map { _ in
            (0..<3).map { _ in game.symbolSet.randomElement() ?? .star }
        }

        let usesLuckyStart = rewardsStore.hasActiveReward("luckyStart")
        let winChance = usesLuckyStart ? 52 : 30
        if Int.random(in: 0..<100) < winChance {
            let winner = game.symbolSet.randomElement() ?? .star
            result = (0..<game.reels).map { column in
                [game.symbolSet.randomElement() ?? .star, winner, game.symbolSet[(column + 1) % game.symbolSet.count]]
            }
        }
        if usesLuckyStart {
            rewardsStore.consumeActiveReward("luckyStart")
        }

        let multiplier = payoutMultiplier(for: result)
        let win = bet * multiplier
        wallet.add(win, to: .coins)
        coins = wallet.coins

        var messages: [String] = []
        if usesFreeSpin {
            messages.append("Free Spin used")
        } else if usesPremiumFreeSpin {
            messages.append("Premium Free Spin used")
        }
        let usesSafeBet = rewardsStore.hasActiveReward("safeBetShield")
        if usesSafeBet && !usesFreeSpin && !usesPremiumFreeSpin {
            if win == 0 {
                let refund = bet / 2
                wallet.add(refund, to: .coins)
                coins = wallet.coins
                messages.append("Coin Shield returned \(Formatters.coins(refund))")
            } else {
                messages.append("Coin Shield protected this spin")
            }
            rewardsStore.consumeActiveReward("safeBetShield")
        }
        if usesLuckyStart {
            messages.append("Lucky Start boosted this spin")
        }

        let usesDoublePoints = rewardsStore.hasActiveReward("doublePointsBoost")
        var pointsEarned = max(8, bet / 20) + max(0, win / 100)
        var gemsEarned = 0
        if usesDoublePoints {
            pointsEarned *= 2
            messages.append("Double Points applied")
            rewardsStore.consumeActiveReward("doublePointsBoost")
        }
        if usesPremiumFreeSpin {
            gemsEarned += 1
            wallet.add(1, to: .gems)
            messages.append("+1 Gem bonus")
        }
        rewardsStore.points += pointsEarned

        let achievementGems = AppAchievementStore.shared.recordSpin(
            win: win,
            hitJackpot: win >= bet * 100
        )
        if achievementGems > 0 {
            gemsEarned += achievementGems
            messages.append("Achievement +\(achievementGems) Gems")
        }

        coins = wallet.coins
        NotificationCenter.default.post(name: .didFinishSpin, object: nil)
        return SpinOutcome(
            result: result,
            win: win,
            jackpot: jackpot,
            pointsEarned: pointsEarned,
            gemsEarned: gemsEarned,
            rewardMessage: messages.isEmpty ? nil : messages.joined(separator: " · ")
        )
    }

    private func payoutMultiplier(for result: [[SlotSymbol]]) -> Int {
        guard result.count >= 3 else { return 0 }
        let middle = result.map { $0.indices.contains(1) ? $0[1] : .star }
        if middle.allSatisfy({ $0 == .seven }) { return 100 }
        if middle.allSatisfy({ $0 == middle.first }) {
            switch middle.first {
            case .star: return 25
            case .diamond: return 15
            case .bar: return 10
            case .cherry: return 5
            default: return 3
            }
        }
        return middle.contains(.seven) && middle.contains(.star) && middle.contains(.diamond) ? 3 : 0
    }
}
