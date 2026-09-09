import Foundation

final class BonusViewModel {
    let game: SlotGame
    let payTable = MockData.payTable

    init(game: SlotGame) {
        self.game = game
    }
}
