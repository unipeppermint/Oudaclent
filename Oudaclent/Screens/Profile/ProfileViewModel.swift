import Foundation

final class ProfileViewModel {
    var user: User {
        var user = MockData.user
        user.points = AppRewardsStore.shared.points
        return user
    }
    let slots = Array(MockData.hotSlots.prefix(2))
    let achievements = MockData.achievements
}
