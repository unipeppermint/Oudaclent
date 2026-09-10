import UIKit

final class LobbyViewController: BaseViewController {
    private let viewModel = LobbyViewModel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func loadView() {
        view = PrototypeBackgroundView(style: .light)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setup()
    }

    private func setup() {
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView) { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(44)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-120)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        contentStack.addArrangedSubview(makeHeader())
        contentStack.addArrangedSubview(makeCheckInBanner())
        contentStack.addArrangedSubview(makeHotHeader())
        contentStack.addArrangedSubview(makeHotSlotsCarousel())
    }

    private func makeHeader() -> UIView {
        let container = UIView()
        let avatar = GradientView(gradient: PrototypeGradient.pinkPurple(), cornerRadius: 44)
        let face = UILabel()
        face.text = "☺"
        face.textAlignment = .center
        face.font = .rounded(size: 32, weight: .black)
        face.textColor = .brandGold

        let title = UILabel()
        title.text = "Hi, Lucky!"
        title.font = .rounded(size: 24, weight: .black)
        title.textColor = .midPurple
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.82

        let subtitle = UILabel()
        subtitle.text = "What do you play today?"
        subtitle.font = .rounded(size: 16, weight: .medium)
        subtitle.textColor = .textSecondary
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.8

        let balance = PrototypeCoinBadge(amount: viewModel.user.coins)

        container.addSubview(avatar)
        avatar.addSubview(face)
        container.addSubview(title)
        container.addSubview(subtitle)
        container.addSubview(balance)

        avatar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.height.equalTo(88)
        }
        face.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        balance.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(112)
            make.height.equalTo(30)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(balance.snp.leading).offset(-8)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(3)
            make.trailing.lessThanOrEqualTo(balance.snp.leading).offset(-8)
        }
        container.snp.makeConstraints { make in
            make.height.equalTo(88)
        }
        return container
    }

    private func makeCheckInBanner() -> UIView {
        let banner = GradientView(gradient: PrototypeGradient.pinkPurple(), cornerRadius: 20)
        banner.applyCardShadow()

        let title = UILabel()
        title.text = "Daily Check-in · Earn Coins"
        title.font = .rounded(size: 22, weight: .black)
        title.textColor = .white
        title.adjustsFontSizeToFitWidth = true

        let subtitle = UILabel()
        subtitle.text = "7-day streak: 1,000 bonus"
        subtitle.font = .body
        subtitle.textColor = UIColor.white.withAlphaComponent(0.9)

        let badge = UIView()
        badge.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        badge.layer.cornerRadius = 27
        let bang = UILabel()
        bang.text = "!"
        bang.font = .rounded(size: 38, weight: .black)
        bang.textColor = .white
        bang.textAlignment = .center

        banner.addSubview(title)
        banner.addSubview(subtitle)
        banner.addSubview(badge)
        badge.addSubview(bang)

        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(22)
            make.trailing.lessThanOrEqualTo(badge.snp.leading).offset(-12)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(4)
            make.trailing.lessThanOrEqualTo(badge.snp.leading).offset(-12)
        }
        badge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(54)
        }
        bang.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        banner.snp.makeConstraints { make in
            make.height.equalTo(80)
        }
        return banner
    }

    private func makeHotHeader() -> UIView {
        let view = UIView()
        let title = UILabel()
        title.text = "Hot Slots"
        title.font = .rounded(size: 26, weight: .black)
        title.textColor = .midPurple
        let all = UILabel()
        all.text = "View All >"
        all.font = .rounded(size: 16, weight: .medium)
        all.textColor = .brandPurple
        all.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.addSubview(title)
        view.addSubview(all)
        title.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        all.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(title.snp.trailing).offset(12)
        }
        view.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        return view
    }

    private func tag(for index: Int) -> (text: String, color: UIColor, background: UIColor) {
        switch index {
        case 0: return ("JACKPOT · 1,000,000", UIColor(hex: "#B45309"), UIColor(hex: "#FEF3C7"))
        case 1: return ("FREE SPIN x 10", UIColor(hex: "#047857"), UIColor(hex: "#CCFBF1"))
        default: return ("BONUS GAME", .midPurple, UIColor(hex: "#EDE9FE"))
        }
    }

    private func makeHotSlotsCarousel() -> UIView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = true
        scroll.clipsToBounds = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 14
        scroll.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scroll.contentLayoutGuide)
            make.height.equalTo(scroll.frameLayoutGuide)
        }

        viewModel.slots.enumerated().forEach { index, game in
            let card = LobbySlotCardView()
            let tagInfo = tag(for: index)
            card.configure(game: game, tag: tagInfo.text, tagColor: tagInfo.color, tagBackground: tagInfo.background)
            card.addAction(UIAction { [weak self] _ in
                (self?.tabBarController as? MainTabBarController)?.showGame(game)
            }, for: .touchUpInside)
            stack.addArrangedSubview(card)
            card.snp.makeConstraints { make in
                make.width.equalTo(280)
            }
        }

        scroll.snp.makeConstraints { make in
            make.height.equalTo(380)
        }
        return scroll
    }
}
