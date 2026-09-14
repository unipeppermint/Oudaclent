import Foundation

struct TreasureBonusResult {
    let chestIndex: Int
    let coinsAwarded: Int
    let wasDoubled: Bool
}

final class BonusViewModel {
    let game: SlotGame
    let payTable = MockData.payTable
    private let defaults: UserDefaults
    private var storageKey: String { "treasureBonus." + game.id }
    private let wallet = AppCurrencyStore.shared
    private let rewardsStore = AppRewardsStore.shared
    private(set) var chestRewards: [Int] = []
    private(set) var selectedChest: Int?
    private(set) var claimedReward: Int?
    private(set) var claimedWithDouble = false

    init(game: SlotGame, defaults: UserDefaults = .standard) {
        self.game = game
        self.defaults = defaults
        if let state = defaults.dictionary(forKey: storageKey),
           let rewards = state["rewards"] as? [Int], rewards.count == 3 {
            chestRewards = rewards
            selectedChest = state["selected"] as? Int
            claimedReward = state["claimed"] as? Int
            claimedWithDouble = state["doubled"] as? Bool ?? false
        } else {
            resetChests()
        }
    }

    var canStartNextPick: Bool {
        selectedChest != nil && rewardsStore.hasActiveReward("bonusPickTicket")
    }

    func startNextPick() -> Bool {
        guard canStartNextPick else { return false }
        rewardsStore.consumeActiveReward("bonusPickTicket")
        resetChests()
        return true
    }

    private func save() {
        var state: [String: Any] = ["rewards": chestRewards, "doubled": claimedWithDouble]
        state["selected"] = selectedChest
        state["claimed"] = claimedReward
        defaults.set(state, forKey: storageKey)
    }

    var isTreasureBonus: Bool {
        game.id == "treasureHunter"
    }

    var gems: Int {
        wallet.gems
    }

    var canReroll: Bool {
        isTreasureBonus && selectedChest == nil
            && defaults.dictionary(forKey: storageKey)?["selected"] == nil
            && rewardsStore.hasActiveReward("treasureReroll")
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
        guard isTreasureBonus, selectedChest == nil,
              defaults.dictionary(forKey: storageKey)?["selected"] == nil,
              chestRewards.indices.contains(index) else {
            return nil
        }

        selectedChest = index
        let wasDoubled = hasDoubleTreasure
        let baseReward = chestRewards[index]
        let reward = wasDoubled ? baseReward * 2 : baseReward
        claimedReward = reward
        claimedWithDouble = wasDoubled
        save()
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
        save()
    }
}
