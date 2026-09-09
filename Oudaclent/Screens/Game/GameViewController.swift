import UIKit

final class GameViewController: BaseViewController {
    private let viewModel: GameViewModel
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let balanceBadge = PrototypeCoinBadge(amount: MockData.user.coins, dark: true)
    private let machine = SlotMachineGrid()
    private let spinButton = SpinButton()
    private let betControl = BetControl()
    private let winLabel = UILabel()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    init(game: SlotGame) {
        self.viewModel = GameViewModel(game: game)
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
        title.font = .rounded(size: 21, weight: .black)
        title.textColor = .white
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.78

        let jackpot = UILabel()
        jackpot.text = "JP  1,000,000"
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

        let titleStack = UIStackView(arrangedSubviews: [title, jackpot])
        titleStack.axis = .vertical
        titleStack.alignment = .center
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
            make.width.equalTo(112)
            make.height.equalTo(33)
        }
        titleStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(back.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(balanceBadge.snp.leading).offset(-10)
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
        contentStack.setCustomSpacing(22, after: winLabel)
        contentStack.addArrangedSubview(betControl)
        betControl.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        contentStack.setCustomSpacing(22, after: betControl)
        contentStack.addArrangedSubview(spinHolder)

        betControl.onChange = { [weak self] value in
            self?.viewModel.bet = value
        }
        spinButton.addAction(UIAction { [weak self] _ in self?.spin() }, for: .touchUpInside)
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
            self.showWin(outcome.win)
        }
    }

    private func showWin(_ win: Int) {
        let visibleWin = win > 0 ? win : 1_500
        winLabel.text = "BIG WIN! +\(Formatters.integer.string(from: NSNumber(value: visibleWin)) ?? "\(visibleWin)")"
        if win >= viewModel.bet * 10 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            BigWinOverlayView().show(amount: win, in: view)
        }
    }
}
