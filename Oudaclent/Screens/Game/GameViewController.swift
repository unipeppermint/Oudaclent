import UIKit

final class GameViewController: BaseViewController {
    private let viewModel: GameViewModel
    private lazy var bonusViewModel = BonusViewModel(game: viewModel.game)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let balanceBadge = PrototypeCoinBadge(
        amount: AppCurrencyStore.shared.coins,
        dark: true,
        fontSize: 13,
        horizontalInset: 3
    )
    private let machine: SlotMachineGrid
    private let spinButton = SpinButton()
    private let betControl = BetControl()
    private let winLabel = UILabel()
    private let jackpotLabel = UILabel()
    private let rewardBanner = ActiveRewardBannerView()
    private let pointsEarnedLabel = UILabel()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    init(game: SlotGame) {
        self.viewModel = GameViewModel(game: game)
        self.machine = SlotMachineGrid(reelCount: game.reels, symbols: game.symbolSet)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = PrototypeBackgroundView(style: .game)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshWallet),
            name: .didUpdateWallet,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshWallet()
        if !spinButton.isSpinning {
            betControl.bet = max(viewModel.game.minBet, AppSettingsStore.shared.settings.betAmount)
        }
        updateRewardBanner()
    }

    private func setup() {
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(contentStack)
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 20
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(74)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-124)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        let back = CircleButton(text: "<", size: 40, background: UIColor.white.withAlphaComponent(0.16), tint: .white)
        back.addAction(UIAction { [weak self] _ in
            (self?.tabBarController as? MainTabBarController)?.showLobby()
        }, for: .touchUpInside)

        let title = UILabel()
        title.text = viewModel.game.title
        title.textColor = .white
        title.textAlignment = .center
        title.numberOfLines = 1
        title.lineBreakMode = .byClipping
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let titleFontSize: CGFloat = viewModel.game.title.count > 12 ? 18 : 21
        title.font = .rounded(size: titleFontSize, weight: .black)
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.78

        let jackpot = jackpotLabel
        jackpot.text = "TOP WIN  x\(viewModel.game.maximumMultiplier)"
        jackpot.font = .rounded(size: 15, weight: .black)
        jackpot.textColor = .brandGold
        jackpot.textAlignment = .center
        jackpot.adjustsFontSizeToFitWidth = true
        jackpot.minimumScaleFactor = 0.78

        winLabel.text = "READY TO SPIN"
        winLabel.font = .rounded(size: 26, weight: .black)
        winLabel.textColor = .brandGold
        winLabel.textAlignment = .center
        winLabel.adjustsFontSizeToFitWidth = true
        winLabel.minimumScaleFactor = 0.72

        pointsEarnedLabel.text = "SPIN TO EARN REWARD POINTS"
        pointsEarnedLabel.font = .rounded(size: 13, weight: .black)
        pointsEarnedLabel.textColor = UIColor.white.withAlphaComponent(0.74)
        pointsEarnedLabel.textAlignment = .center
        pointsEarnedLabel.numberOfLines = 2
        pointsEarnedLabel.adjustsFontSizeToFitWidth = true
        pointsEarnedLabel.minimumScaleFactor = 0.72

        let titleStack = UIStackView(arrangedSubviews: [title, jackpot])
        titleStack.axis = .vertical
        titleStack.alignment = .fill
        titleStack.spacing = 4

        let header = UIView()
        header.addSubview(back)
        header.addSubview(titleStack)
        header.addSubview(balanceBadge)
        back.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        balanceBadge.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(84)
            make.height.equalTo(30)
        }
        titleStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(188)
            make.leading.greaterThanOrEqualTo(back.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(balanceBadge.snp.leading).offset(-2)
        }
        header.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        let spinHolder = UIView()
        spinHolder.addSubview(spinButton)
        spinButton.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.width.height.equalTo(88)
        }

        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(18, after: header)
        contentStack.addArrangedSubview(rewardBanner)
        rewardBanner.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        contentStack.setCustomSpacing(14, after: rewardBanner)
        contentStack.addArrangedSubview(machine)
        machine.snp.makeConstraints { make in
            make.height.equalTo(machine.snp.width).multipliedBy(0.78).priority(750)
            make.height.lessThanOrEqualTo(292)
            make.height.greaterThanOrEqualTo(220)
        }
        contentStack.addArrangedSubview(winLabel)
        winLabel.snp.makeConstraints { make in
            make.height.equalTo(42)
        }
        contentStack.setCustomSpacing(6, after: winLabel)
        contentStack.addArrangedSubview(pointsEarnedLabel)
        pointsEarnedLabel.snp.makeConstraints { make in
            make.height.equalTo(34)
        }
        contentStack.setCustomSpacing(22, after: pointsEarnedLabel)
        contentStack.addArrangedSubview(betControl)
        betControl.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        contentStack.setCustomSpacing(22, after: betControl)
        contentStack.addArrangedSubview(spinHolder)
        if viewModel.game.id == "treasureHunter" {
            contentStack.addArrangedSubview(makeBonusLink())
        }

        betControl.minimumBet = viewModel.game.minBet
        betControl.bet = viewModel.bet
        betControl.onChange = { [weak self] value in
            self?.viewModel.bet = value
        }
        spinButton.addAction(UIAction { [weak self] _ in self?.spin() }, for: .touchUpInside)
        updateRewardBanner()
    }

    private func spin() {
        guard !spinButton.isSpinning else { return }
        guard let outcome = viewModel.spin() else {
            let alert = UIAlertController(title: "Not Enough Coins", message: "Lower Coins per Spin, collect your daily check-in, or redeem a Free Spin Ticket in Rewards.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Rewards", style: .default) { [weak self] _ in
                (self?.tabBarController as? MainTabBarController)?.showRewards()
            })
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
            return
        }
        spinButton.isSpinning = true
        betControl.isUserInteractionEnabled = false
        balanceBadge.configure(amount: viewModel.coins)
        GameFeedback.spin()
        machine.spinAll(outcome.result) { [weak self] in
            guard let self else { return }
            self.spinButton.isSpinning = false
            self.betControl.isUserInteractionEnabled = true
            self.balanceBadge.configure(amount: self.viewModel.coins)
            self.showWin(outcome)
            self.updateRewardBanner()
        }
    }

    private func showWin(_ outcome: SpinOutcome) {
        let win = outcome.win
        winLabel.text = win > 0 ? "WIN! +\(Formatters.integer.string(from: NSNumber(value: win)) ?? "\(win)")" : "NO WIN THIS SPIN"
        var earnedText = "+\(Formatters.integer.string(from: NSNumber(value: outcome.pointsEarned)) ?? "\(outcome.pointsEarned)") POINTS"
        if outcome.gemsEarned > 0 {
            earnedText += " · +\(outcome.gemsEarned) GEMS"
        }
        pointsEarnedLabel.text = outcome.rewardMessage.map { "\(earnedText) · \($0)" } ?? earnedText
        if win >= viewModel.bet * 10 {
            GameFeedback.reward()
            BigWinOverlayView().show(amount: win, in: view)
        }
    }

    @objc private func refreshWallet() {
        viewModel.refreshBalances()
        balanceBadge.configure(amount: viewModel.coins)
    }

    private func makeBonusLink() -> UIView {
        let link = UIControl()
        link.backgroundColor = UIColor.white.withAlphaComponent(0.14)
        link.layer.cornerRadius = 16
        link.layer.cornerCurve = .continuous
        link.layer.borderWidth = 1
        link.layer.borderColor = UIColor.brandGold.withAlphaComponent(0.38).cgColor
        link.addPressAnimation()

        let icon = UIImageView(image: UIImage(systemName: "gift.fill"))
        icon.tintColor = .brandGold
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "Treasure Bonus"
        title.font = .rounded(size: 15, weight: .black)
        title.textColor = .white

        let subtitle = UILabel()
        subtitle.text = "Pick a chest and use Gems for premium boosts"
        subtitle.font = .rounded(size: 12, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.72)
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.72

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor.white.withAlphaComponent(0.72)
        arrow.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.isUserInteractionEnabled = false

        link.addSubview(icon)
        link.addSubview(textStack)
        link.addSubview(arrow)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.equalTo(12)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(12)
            make.trailing.equalTo(arrow.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        link.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
        link.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let tabs = self.tabBarController as? MainTabBarController
            let bonus = BonusViewController(viewModel: self.bonusViewModel, onOpenStore: { [weak tabs] currency in
                tabs?.showRewards(currency: currency)
            })
            self.present(bonus, animated: true)
        }, for: .touchUpInside)
        return link
    }

    private func updateRewardBanner() {
        let rewards = AppRewardsStore.shared.activeRewards
        rewardBanner.configure(rewards)
        rewardBanner.isHidden = rewards.isEmpty
    }
}

private final class ActiveRewardBannerView: UIView {
    private let titleLabel = UILabel()
    private let iconStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = UIColor.white.withAlphaComponent(0.16)
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        titleLabel.font = .rounded(size: 13, weight: .black)
        titleLabel.textColor = .white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.72

        iconStack.axis = .horizontal
        iconStack.spacing = 6
        iconStack.alignment = .center

        addSubview(titleLabel)
        addSubview(iconStack)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(iconStack.snp.leading).offset(-10)
        }
        iconStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    func configure(_ rewards: [RewardItem]) {
        titleLabel.text = rewards.count == 1 ? rewards[0].title : "\(rewards.count) ACTIVE REWARDS"
        iconStack.arrangedSubviews.forEach { view in
            iconStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        rewards.prefix(4).forEach { reward in
            iconStack.addArrangedSubview(makeIcon(reward))
        }
    }

    private func makeIcon(_ reward: RewardItem) -> UIView {
        let view = UIView()
        view.backgroundColor = reward.accentColor
        view.layer.cornerRadius = 13
        view.layer.masksToBounds = true

        let icon = UIImageView(image: UIImage(systemName: reward.iconName))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        view.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(13)
        }
        view.snp.makeConstraints { make in
            make.width.height.equalTo(26)
        }
        return view
    }
}
