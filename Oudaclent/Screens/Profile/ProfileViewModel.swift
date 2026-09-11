import Foundation

final class ProfileViewModel {
    var user: User {
        var user = MockData.user
        user.coins = AppCurrencyStore.shared.coins
        user.gems = AppCurrencyStore.shared.gems
        user.points = AppRewardsStore.shared.points
        return user
    }
    let slots = Array(MockData.hotSlots.prefix(2))

    var achievements: [Achievement] {
        AppAchievementStore.shared.achievements
    }
}
