import UIKit

final class GameViewController: BaseViewController {
    private let viewModel: GameViewModel
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let balanceBadge = PrototypeCoinBadge(
        amount: MockData.user.coins,
        dark: true,
        fontSize: 13,
        horizontalInset: 3
    )
    private let machine: SlotMachineGrid
    private let spinButton = SpinButton()
    private let betControl = BetControl()
    private let winLabel = UILabel()
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

        let jackpot = UILabel()
        jackpot.text = "JP  \(Formatters.integer.string(from: NSNumber(value: viewModel.game.jackpotPool)) ?? "\(viewModel.game.jackpotPool)")"
        jackpot.font = .rounded(size: 15, weight: .black)
        jackpot.textColor = .brandGold
        jackpot.textAlignment = .center
        jackpot.adjustsFontSizeToFitWidth = true
        jackpot.minimumScaleFactor = 0.78

        winLabel.text = "BIG WIN! +1,500"
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
            make.width.equalTo(188)
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
            make.height.equalTo(machine.snp.width).multipliedBy(0.78)
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

        betControl.minimumBet = viewModel.game.minBet
        betControl.bet = viewModel.bet
        betControl.onChange = { [weak self] value in
            self?.viewModel.bet = value
        }
        spinButton.addAction(UIAction { [weak self] _ in self?.spin() }, for: .touchUpInside)
        updateRewardBanner()
    }

    private func spin() {
        guard let outcome = viewModel.spin() else { return }
        spinButton.isSpinning = true
        balanceBadge.configure(amount: viewModel.coins)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        machine.spinAll(outcome.result) { [weak self] in
            guard let self else { return }
            self.spinButton.isSpinning = false
            self.balanceBadge.configure(amount: self.viewModel.coins)
            self.showWin(outcome)
            self.updateRewardBanner()
        }
    }

    private func showWin(_ outcome: SpinOutcome) {
        let win = outcome.win
        let visibleWin = win > 0 ? win : 1_500
        winLabel.text = "BIG WIN! +\(Formatters.integer.string(from: NSNumber(value: visibleWin)) ?? "\(visibleWin)")"
        let pointsText = "+\(Formatters.integer.string(from: NSNumber(value: outcome.pointsEarned)) ?? "\(outcome.pointsEarned)") POINTS"
        if let rewardMessage = outcome.rewardMessage {
            pointsEarnedLabel.text = "\(pointsText) · \(rewardMessage)"
        } else {
            pointsEarnedLabel.text = pointsText
        }
        if win >= viewModel.bet * 10 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            BigWinOverlayView().show(amount: win, in: view)
        }
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
