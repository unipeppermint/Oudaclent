import Foundation

final class ProfileViewModel {
    let user = MockData.user
    let slots = Array(MockData.hotSlots.prefix(2))
    let achievements = MockData.achievements
}
