import Foundation

extension Notification.Name {
    static let didFinishSpin = Notification.Name("didFinishSpin")
}

struct SpinOutcome {
    let result: [[SlotSymbol]]
    let win: Int
    let jackpot: Int
    let pointsEarned: Int
    let rewardMessage: String?
}

final class GameViewModel {
    let game: SlotGame
    private(set) var coins: Int
    private(set) var jackpot: Int
    var bet: Int

    init(game: SlotGame, user: User = MockData.user) {
        self.game = game
        self.coins = user.coins
        self.jackpot = game.jackpotPool
        self.bet = max(game.minBet, AppSettingsStore.shared.settings.betAmount)
    }

    func spin() -> SpinOutcome? {
        let rewardsStore = AppRewardsStore.shared
        let usesFreeSpin = rewardsStore.hasActiveReward("freeSpinTicket")
        guard usesFreeSpin || coins >= bet else { return nil }
        if usesFreeSpin {
            rewardsStore.consumeActiveReward("freeSpinTicket")
        } else {
            coins -= bet
        }
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
        coins += win

        var messages: [String] = []
        if usesFreeSpin {
            messages.append("Free Spin used")
        }
        let usesSafeBet = rewardsStore.hasActiveReward("safeBetShield")
        if usesSafeBet {
            if win == 0 {
                let refund = bet / 2
                coins += refund
                messages.append("Safe Bet refunded \(Formatters.coins(refund))")
            } else {
                messages.append("Safe Bet protected this spin")
            }
            rewardsStore.consumeActiveReward("safeBetShield")
        }
        if usesLuckyStart {
            messages.append("Lucky Start boosted this spin")
        }

        let usesDoublePoints = rewardsStore.hasActiveReward("doublePointsBoost")
        var pointsEarned = max(8, bet / 20) + max(0, win / 100)
        if usesDoublePoints {
            pointsEarned *= 2
            messages.append("Double Points applied")
            rewardsStore.consumeActiveReward("doublePointsBoost")
        }
        rewardsStore.points += pointsEarned

        NotificationCenter.default.post(name: .didFinishSpin, object: nil)
        return SpinOutcome(
            result: result,
            win: win,
            jackpot: jackpot,
            pointsEarned: pointsEarned,
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
