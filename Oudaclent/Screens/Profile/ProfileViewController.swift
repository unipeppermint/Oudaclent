import UIKit

final class ProfileViewController: BaseViewController {
    private let viewModel = ProfileViewModel()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private weak var pointsValueLabel: UILabel?

    override func loadView() {
        view = PrototypeBackgroundView(style: .light)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setup()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshPoints),
            name: .didUpdateRewards,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshPoints()
    }

    private func setup() {
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView) { make in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(46)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-124)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        contentStack.addArrangedSubview(makeTopBar())
        contentStack.setCustomSpacing(26, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(makeUserCard())
        contentStack.addArrangedSubview(makeCurrencies())
        contentStack.addArrangedSubview(makeSectionHeader(title: "My Slots", action: "View All >") { [weak self] in
            self?.showMySlotsPage()
        })
        contentStack.addArrangedSubview(makeMySlots())
        contentStack.addArrangedSubview(makeSectionHeader(title: "Achievements", action: "View All >") { [weak self] in
            self?.showAchievementsPage()
        })
        contentStack.addArrangedSubview(makeAchievements())
    }

    private func showMySlotsPage() {
        navigationController?.pushViewController(
            GameListViewController(title: "My Slots", games: viewModel.slots),
            animated: true
        )
    }

    private func showAchievementsPage() {
        navigationController?.pushViewController(
            AchievementsListViewController(achievements: viewModel.achievements),
            animated: true
        )
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let title = UILabel()
        title.text = "Profile"
        title.font = .rounded(size: 26, weight: .black)
        title.textColor = .midPurple
        let settings = CircleButton(text: "⚙", size: 40, background: .white, tint: .textSecondary)
        settings.addAction(UIAction { [weak self] _ in
            (self?.tabBarController as? MainTabBarController)?.showSettings()
        }, for: .touchUpInside)

        bar.addSubview(title)
        bar.addSubview(settings)
        title.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        settings.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        bar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return bar
    }

    private func makeUserCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 24
        card.applySoftShadow()

        let avatar = GradientView(gradient: PrototypeGradient.pinkPurple(), cornerRadius: 40)
        avatar.layer.borderWidth = 3
        avatar.layer.borderColor = UIColor.brandGold.cgColor
        let face = UILabel()
        face.text = "☺"
        face.font = .rounded(size: 36, weight: .black)
        face.textColor = .brandGold
        face.textAlignment = .center

        let name = UILabel()
        name.text = viewModel.user.nickname
        name.font = .rounded(size: 24, weight: .black)
        name.textColor = .midPurple
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.78

        let tier = PaddingLabel()
        tier.text = "LV 12 · Gold Member"
        tier.font = .rounded(size: 13, weight: .black)
        tier.textColor = UIColor(hex: "#B45309")
        tier.backgroundColor = UIColor(hex: "#FEF3C7")
        tier.layer.cornerRadius = 10
        tier.layer.masksToBounds = true
        tier.adjustsFontSizeToFitWidth = true
        tier.minimumScaleFactor = 0.78

        card.addSubview(avatar)
        avatar.addSubview(face)
        card.addSubview(name)
        card.addSubview(tier)

        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(80)
        }
        face.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(31)
            make.trailing.equalToSuperview().offset(-16)
        }
        tier.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(22)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(110)
        }
        return card
    }

    private func makeCurrencies() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        [
            ("★", viewModel.user.coins, "COINS", CAGradientLayer.goldGradient()),
            ("♦", viewModel.user.gems, "GEMS", PrototypeGradient.cyan()),
            ("●", viewModel.user.points, "POINTS", PrototypeGradient.pinkPurple())
        ].forEach { item in
            stack.addArrangedSubview(makeCurrency(icon: item.0, value: item.1, title: item.2, gradient: item.3))
        }
        stack.snp.makeConstraints { make in
            make.height.equalTo(96)
        }
        return stack
    }

    private func makeCurrency(icon: String, value: Int, title: String, gradient: CAGradientLayer) -> UIView {
        let card = GradientView(gradient: gradient, cornerRadius: 16)
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.textColor = .white
        iconLabel.font = .rounded(size: 24, weight: .black)
        let valueLabel = UILabel()
        valueLabel.text = Formatters.integer.string(from: NSNumber(value: value))
        valueLabel.textColor = .white
        valueLabel.font = .rounded(size: 22, weight: .black)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.74
        if title == "POINTS" {
            pointsValueLabel = valueLabel
        }
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .caption
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78

        card.addSubview(iconLabel)
        card.addSubview(valueLabel)
        card.addSubview(titleLabel)
        iconLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(12)
        }
        valueLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(iconLabel.snp.bottom).offset(10)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(valueLabel)
            make.top.equalTo(valueLabel.snp.bottom).offset(4)
        }
        return card
    }

    @objc private func refreshPoints() {
        pointsValueLabel?.text = Formatters.integer.string(from: NSNumber(value: AppRewardsStore.shared.points))
    }

    private func makeSectionHeader(title: String, action: String, onTap: @escaping () -> Void) -> UIView {
        let view = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 21, weight: .black)
        titleLabel.textColor = .midPurple
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.82
        let actionButton = UIButton(type: .system)
        actionButton.setTitle(action, for: .normal)
        actionButton.titleLabel?.font = .rounded(size: 15, weight: .medium)
        actionButton.setTitleColor(.brandPurple, for: .normal)
        actionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionButton.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
        view.addSubview(titleLabel)
        view.addSubview(actionButton)
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        actionButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(12)
        }
        view.snp.makeConstraints { make in
            make.height.equalTo(32)
        }
        return view
    }

    private func makeMySlots() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.addArrangedSubview(makeMiniSlot(title: "Lucky 7", subtitle: "Max x1000", symbol: .seven))
        stack.addArrangedSubview(makeMiniSlot(title: "Sweet Candy", subtitle: "Free Spin x10", symbol: .cherry))
        stack.snp.makeConstraints { make in
            make.height.equalTo(116)
        }
        return stack
    }

    private func makeMiniSlot(title: String, subtitle: String, symbol: SlotSymbol) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.applySoftShadow()
        let tile = SymbolTile(symbol: symbol, gradient: PrototypeGradient.seven(), cornerRadius: 12, fontSize: 31)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 17, weight: .black)
        titleLabel.textColor = .midPurple
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .caption
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.74

        card.addSubview(tile)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        tile.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(12)
            make.width.height.equalTo(44)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(tile.snp.bottom).offset(10)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
        return card
    }

    private func makeAchievements() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.addArrangedSubview(makeAchievement(symbol: "7", title: "First Jackpot", state: "Unlocked", unlocked: true))
        stack.addArrangedSubview(makeAchievement(symbol: "★", title: "10 Win Streak", state: "7/10", unlocked: true))
        stack.addArrangedSubview(makeAchievement(symbol: "?", title: "100 Win Streak", state: "Locked", unlocked: false))
        stack.snp.makeConstraints { make in
            make.height.equalTo(112)
        }
        return stack
    }

    private func makeAchievement(symbol: String, title: String, state: String, unlocked: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = unlocked ? .white : UIColor.white.withAlphaComponent(0.42)
        card.layer.cornerRadius = 16
        if unlocked {
            card.applySoftShadow()
        } else {
            card.layer.borderWidth = 1.5
            card.layer.borderColor = UIColor.brandPurple.withAlphaComponent(0.25).cgColor
        }

        let icon = UILabel()
        icon.text = symbol
        icon.textAlignment = .center
        icon.font = .rounded(size: 22, weight: .black)
        icon.textColor = .white
        icon.backgroundColor = unlocked ? (symbol == "7" ? UIColor(hex: "#FF5D85") : .brandGold) : UIColor.locked.withAlphaComponent(0.35)
        icon.layer.cornerRadius = 20
        icon.layer.masksToBounds = true
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 12, weight: .black)
        titleLabel.textAlignment = .center
        titleLabel.textColor = unlocked ? .midPurple : .locked
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.76
        let stateLabel = UILabel()
        stateLabel.text = state
        stateLabel.font = .caption
        stateLabel.textAlignment = .center
        stateLabel.textColor = unlocked ? (state == "Unlocked" ? .success : .accentOrange) : .locked

        card.addSubview(icon)
        card.addSubview(titleLabel)
        card.addSubview(stateLabel)
        icon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(40)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.equalTo(icon.snp.bottom).offset(8)
        }
        stateLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.lessThanOrEqualToSuperview().offset(-8)
        }
        return card
    }
}

private final class AchievementsListViewController: BaseViewController {
    private let achievements: [Achievement]
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(achievements: [Achievement]) {
        self.achievements = achievements
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
        contentStack.spacing = 12
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(58)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-126)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        contentStack.addArrangedSubview(makeTopBar())
        contentStack.setCustomSpacing(24, after: contentStack.arrangedSubviews.last!)

        achievements.forEach { achievement in
            let card = AchievementCardView()
            card.configure(ach: achievement)
            card.snp.makeConstraints { make in
                make.height.equalTo(104)
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
        title.text = "Achievements"
        title.textAlignment = .center
        title.font = .rounded(size: 24, weight: .black)
        title.textColor = .midPurple

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
}
