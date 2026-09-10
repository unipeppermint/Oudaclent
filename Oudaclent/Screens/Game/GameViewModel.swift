import Foundation

extension Notification.Name {
    static let didFinishSpin = Notification.Name("didFinishSpin")
}

struct SpinOutcome {
    let result: [[SlotSymbol]]
    let win: Int
    let jackpot: Int
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
        guard coins >= bet else { return nil }
        coins -= bet
        jackpot += Int(Double(bet) * 0.08)

        var result = (0..<game.reels).map { _ in
            (0..<3).map { _ in game.symbolSet.randomElement() ?? .star }
        }

        if Int.random(in: 0..<100) < 30 {
            let winner = game.symbolSet.randomElement() ?? .star
            result = (0..<game.reels).map { column in
                [game.symbolSet.randomElement() ?? .star, winner, game.symbolSet[(column + 1) % game.symbolSet.count]]
            }
        }

        let multiplier = payoutMultiplier(for: result)
        let win = bet * multiplier
        coins += win
        NotificationCenter.default.post(name: .didFinishSpin, object: nil)
        return SpinOutcome(result: result, win: win, jackpot: jackpot)
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
