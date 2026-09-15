import UIKit

final class LobbyViewController: BaseViewController {
    private let viewModel = LobbyViewModel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let balanceBadge = PrototypeCoinBadge(amount: AppCurrencyStore.shared.coins)
    private let checkInBanner = CheckInBannerView()

    override func loadView() {
        view = PrototypeBackgroundView(style: .light)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setup()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshHome),
            name: .didUpdateWallet,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshHome),
            name: .didUpdateEngagement,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshHome()
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
        title.text = "VaultSpin Slot"
        title.font = .rounded(size: 24, weight: .black)
        title.textColor = .midPurple
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.82

        let subtitle = UILabel()
        subtitle.text = "Choose a game."
        subtitle.font = .rounded(size: 16, weight: .medium)
        subtitle.textColor = .textSecondary
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.8

        container.addSubview(avatar)
        avatar.addSubview(face)
        container.addSubview(title)
        container.addSubview(subtitle)
        container.addSubview(balanceBadge)

        avatar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.height.equalTo(88)
        }
        face.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        balanceBadge.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(112)
            make.height.equalTo(30)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(balanceBadge.snp.leading).offset(-8)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(3)
            make.trailing.lessThanOrEqualTo(balanceBadge.snp.leading).offset(-8)
        }
        container.snp.makeConstraints { make in
            make.height.equalTo(88)
        }
        return container
    }

    private func makeCheckInBanner() -> UIView {
        checkInBanner.configure(
            streak: AppEngagementStore.shared.nextCheckInReward.streak,
            canCheckIn: AppEngagementStore.shared.canCheckIn,
            nextReward: (
                coins: AppEngagementStore.shared.nextCheckInReward.coins,
                gems: AppEngagementStore.shared.nextCheckInReward.gems
            ),
            onCheckIn: { [weak self] in self?.claimCheckIn() }
        )
        checkInBanner.snp.makeConstraints { make in
            make.height.equalTo(80)
        }
        return checkInBanner
    }

    @objc private func refreshHome() {
        balanceBadge.configure(amount: AppCurrencyStore.shared.coins)
        let engagement = AppEngagementStore.shared
        let reward = engagement.nextCheckInReward
        checkInBanner.configure(
            streak: reward.streak,
            canCheckIn: engagement.canCheckIn,
            nextReward: (coins: reward.coins, gems: reward.gems),
            onCheckIn: { [weak self] in self?.claimCheckIn() }
        )
    }

    private func claimCheckIn() {
        guard let result = AppEngagementStore.shared.checkIn() else { return }
        showMessage(
            title: "Daily Reward Claimed",
            message: "Day \(min(7, result.streak))/7 · +\(result.coins) Coins · +\(result.gems) Gems"
        )
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func makeHotHeader() -> UIView {
        let view = UIView()
        let title = UILabel()
        title.text = "Games"
        title.font = .rounded(size: 26, weight: .black)
        title.textColor = .midPurple
        let all = UIButton(type: .system)
        all.setTitle("View All >", for: .normal)
        all.titleLabel?.font = .rounded(size: 16, weight: .medium)
        all.setTitleColor(.brandPurple, for: .normal)
        all.setContentCompressionResistancePriority(.required, for: .horizontal)
        all.addAction(UIAction { [weak self] _ in
            self?.showAllGames()
        }, for: .touchUpInside)
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

    private func showAllGames() {
        navigationController?.pushViewController(
            GameListViewController(title: "All Games", games: viewModel.slots),
            animated: true
        )
    }

    private func tag(for index: Int) -> (text: String, color: UIColor, background: UIColor) {
        switch index {
        case 0: return ("TOP WIN · x100", UIColor(hex: "#B45309"), UIColor(hex: "#FEF3C7"))
        case 1: return ("5-REEL GAME", UIColor(hex: "#047857"), UIColor(hex: "#CCFBF1"))
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

final class GameListViewController: BaseViewController {
    private let pageTitle: String
    private let games: [SlotGame]
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(title: String, games: [SlotGame]) {
        self.pageTitle = title
        self.games = games
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        contentStack.spacing = 14
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(58)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-126)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        contentStack.addArrangedSubview(makeTopBar())
        contentStack.setCustomSpacing(24, after: contentStack.arrangedSubviews.last!)

        games.enumerated().forEach { index, game in
            let card = LobbySlotCardView()
            let tag = tag(for: index)
            card.configure(game: game, tag: tag.text, tagColor: tag.color, tagBackground: tag.background)
            card.addAction(UIAction { [weak self] _ in
                (self?.tabBarController as? MainTabBarController)?.showGame(game)
            }, for: .touchUpInside)
            card.snp.makeConstraints { make in
                make.height.equalTo(380)
            }
            contentStack.addArrangedSubview(card)
        }
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let back = CircleButton(text: "<", size: 40, background: .white, tint: .midPurple)
        back.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = UILabel()
        title.text = pageTitle
        title.textAlignment = .center
        title.font = .rounded(size: 24, weight: .black)
        title.textColor = .midPurple
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.78

        bar.addSubview(back)
        bar.addSubview(title)
        back.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        title.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(back.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }
        bar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return bar
    }

    private func tag(for index: Int) -> (text: String, color: UIColor, background: UIColor) {
        switch index {
        case 0:
            return ("TOP WIN · x100", UIColor(hex: "#B45309"), UIColor(hex: "#FEF3C7"))
        case 1:
            return ("5-REEL GAME", UIColor(hex: "#047857"), UIColor(hex: "#CCFBF1"))
        default:
            return ("BONUS GAME", .midPurple, UIColor(hex: "#EDE9FE"))
        }
    }
}
