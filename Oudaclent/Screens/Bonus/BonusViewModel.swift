import Foundation

struct TreasureBonusResult {
    let chestIndex: Int
    let coinsAwarded: Int
    let wasDoubled: Bool
}

final class BonusViewModel {
    let game: SlotGame
    let payTable = MockData.payTable
    private let wallet = AppCurrencyStore.shared
    private let rewardsStore = AppRewardsStore.shared
    private(set) var chestRewards: [Int] = []
    private(set) var selectedChest: Int?
    private(set) var claimedReward: Int?
    private(set) var claimedWithDouble = false

    init(game: SlotGame) {
        self.game = game
        resetChests()
    }

    var isTreasureBonus: Bool {
        game.id == "treasureHunter"
    }

    var gems: Int {
        wallet.gems
    }

    var canReroll: Bool {
        isTreasureBonus && selectedChest == nil && rewardsStore.hasActiveReward("treasureReroll")
    }

    var hasDoubleTreasure: Bool {
        rewardsStore.hasActiveReward("doubleTreasure")
    }

    @discardableResult
    func reroll() -> Bool {
        guard canReroll else { return false }
        rewardsStore.consumeActiveReward("treasureReroll")
        resetChests()
        return true
    }

    func claimChest(at index: Int) -> TreasureBonusResult? {
        guard isTreasureBonus, selectedChest == nil, chestRewards.indices.contains(index) else {
            return nil
        }

        selectedChest = index
        let wasDoubled = hasDoubleTreasure
        let baseReward = chestRewards[index]
        let reward = wasDoubled ? baseReward * 2 : baseReward
        claimedReward = reward
        claimedWithDouble = wasDoubled
        wallet.add(reward, to: .coins)
        if wasDoubled {
            rewardsStore.consumeActiveReward("doubleTreasure")
        }
        return TreasureBonusResult(chestIndex: index, coinsAwarded: reward, wasDoubled: wasDoubled)
    }

    private func resetChests() {
        chestRewards = [500, 1_000, 2_500].map { $0 + Int.random(in: 0...250) }
        selectedChest = nil
        claimedReward = nil
        claimedWithDouble = false
    }
}
