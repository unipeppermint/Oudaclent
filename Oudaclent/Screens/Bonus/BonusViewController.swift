import UIKit

final class BonusViewController: BaseViewController {
    private let viewModel: BonusViewModel
    private let onOpenStore: (RewardCurrency) -> Void
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let chestStack = UIStackView()
    private var chestButtons: [UIControl] = []
    private var chestValueLabels: [UILabel] = []
    private weak var gemsLabel: UILabel?
    private weak var bonusStatusLabel: UILabel?
    private weak var doubleBadge: PaddingLabel?
    private let rerollButton = PrimaryButton(title: "REROLL READY", gradient: PrototypeGradient.cyan())

    init(viewModel: BonusViewModel, onOpenStore: @escaping (RewardCurrency) -> Void) {
        self.viewModel = viewModel
        self.onOpenStore = onOpenStore
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
            make.top.equalTo(scrollView.contentLayoutGuide).offset(28)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-120)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        contentStack.addArrangedSubview(makeTopBar())
        contentStack.setCustomSpacing(28, after: contentStack.arrangedSubviews.last!)
        if viewModel.isTreasureBonus {
            contentStack.addArrangedSubview(makeTreasureBonus())
        } else {
            contentStack.addArrangedSubview(makeHero())
            contentStack.addArrangedSubview(makeFeatureRow())
            contentStack.addArrangedSubview(makePayTable())
        }
        contentStack.addArrangedSubview(makeCTA())
        updateTreasureBonusUI()
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let back = CircleButton(text: "<", size: 40, background: .white, tint: .midPurple)
        back.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if let navigationController = self.navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }, for: .touchUpInside)
        let title = UILabel()
        title.text = viewModel.isTreasureBonus ? "Treasure Bonus" : "\(viewModel.game.title) Features"
        title.font = .rounded(size: 24, weight: .black)
        title.textColor = .midPurple
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.72
        let heart = UIView()
        heart.snp.makeConstraints { $0.width.height.equalTo(40) }

        bar.addSubview(back)
        bar.addSubview(title)
        bar.addSubview(heart)
        back.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        heart.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        title.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(back.snp.trailing).offset(10)
            make.trailing.lessThanOrEqualTo(heart.snp.leading).offset(-10)
        }
        bar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return bar
    }

    private func makeHero() -> UIView {
        let hero = GradientView(gradient: PrototypeGradient.pinkPurple(), cornerRadius: 24)
        hero.applyCardShadow()

        let chip = PaddingLabel()
        chip.text = "JACKPOT"
        chip.font = .rounded(size: 12, weight: .black)
        chip.textColor = .white
        chip.textAlignment = .center
        chip.insets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        chip.backgroundColor = .brandGold
        chip.layer.cornerRadius = 10
        chip.layer.masksToBounds = true

        let amount = UILabel()
        amount.text = Formatters.integer.string(from: NSNumber(value: viewModel.game.jackpotPool)) ?? "\(viewModel.game.jackpotPool)"
        amount.font = .rounded(size: 30, weight: .black)
        amount.textColor = .brandGold
        amount.adjustsFontSizeToFitWidth = true
        amount.minimumScaleFactor = 0.72
        let name = UILabel()
        name.text = viewModel.game.title
        name.font = .rounded(size: 22, weight: .black)
        name.textColor = .white
        name.adjustsFontSizeToFitWidth = true
        name.minimumScaleFactor = 0.75
        let subtitle = UILabel()
        subtitle.text = viewModel.game.subtitle.replacingOccurrences(of: " · ", with: "  •  ")
        subtitle.font = .rounded(size: 15, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.78

        let circle = UIView()
        circle.backgroundColor = .white
        circle.layer.cornerRadius = 45
        circle.layer.borderWidth = 3
        circle.layer.borderColor = UIColor.brandGold.cgColor
        let seven = UILabel()
        seven.text = "7"
        seven.font = .rounded(size: 54, weight: .black)
        seven.textColor = UIColor(hex: "#FF416B")
        seven.textAlignment = .center

        hero.addSubview(chip)
        hero.addSubview(amount)
        hero.addSubview(name)
        hero.addSubview(subtitle)
        hero.addSubview(circle)
        circle.addSubview(seven)

        chip.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(24)
            make.height.equalTo(18)
        }
        amount.snp.makeConstraints { make in
            make.leading.equalTo(chip)
            make.top.equalTo(chip.snp.bottom).offset(10)
            make.trailing.lessThanOrEqualTo(circle.snp.leading).offset(-12)
        }
        name.snp.makeConstraints { make in
            make.leading.equalTo(chip)
            make.top.equalTo(amount.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualTo(circle.snp.leading).offset(-12)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(chip)
            make.top.equalTo(name.snp.bottom).offset(6)
            make.trailing.lessThanOrEqualTo(circle.snp.leading).offset(-12)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
        circle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(90)
        }
        seven.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        hero.snp.makeConstraints { make in
            make.height.equalTo(160)
        }
        return hero
    }

    private func makeFeatureRow() -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        viewModel.game.features.prefix(3).enumerated().forEach { index, feature in
            let colors: [UIColor] = [.brandGold, .accentCyan, .brandPink]
            let symbol = viewModel.game.symbolSet.indices.contains(index) ? viewModel.game.symbolSet[index].display : "★"
            stack.addArrangedSubview(makeFeatureCard(icon: symbol, title: feature.title, subtitle: feature.description, color: colors[index % colors.count]))
        }
        stack.snp.makeConstraints { make in
            make.height.equalTo(118)
        }
        return stack
    }

    private func makeFeatureCard(icon: String, title: String, subtitle: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 18
        card.applySoftShadow()
        let iconCircle = UILabel()
        iconCircle.text = icon
        iconCircle.textAlignment = .center
        iconCircle.textColor = .white
        iconCircle.font = .rounded(size: 24, weight: .black)
        iconCircle.backgroundColor = color
        iconCircle.layer.cornerRadius = 16
        iconCircle.layer.masksToBounds = true
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 14, weight: .black)
        titleLabel.textColor = .midPurple
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .caption
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.numberOfLines = 2
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.78

        card.addSubview(iconCircle)
        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        iconCircle.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(12)
            make.width.height.equalTo(32)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(iconCircle.snp.bottom).offset(12)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        return card
    }

    private func makePayTable() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.applySoftShadow()

        let title = UILabel()
        title.text = "Pay Table"
        title.font = .rounded(size: 24, weight: .black)
        title.textColor = .midPurple
        let label = UILabel()
        label.text = "Paytable"
        label.font = .body
        label.textColor = .textSecondary

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 8
        [
            (SlotSymbol.seven, "x 1,000"),
            (SlotSymbol.star, "x 200"),
            (SlotSymbol.cherry, "x 100"),
            (SlotSymbol.diamond, "x 50")
        ].forEach { row in rows.addArrangedSubview(makePayRow(symbol: row.0, payout: row.1)) }

        card.addSubview(title)
        card.addSubview(label)
        card.addSubview(rows)
        title.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
        }
        label.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalTo(title)
        }
        rows.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-13)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(230)
        }
        return card
    }

    private func makeTreasureBonus() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.applySoftShadow()

        let title = UILabel()
        title.text = "Treasure Bonus"
        title.font = .rounded(size: 22, weight: .black)
        title.textColor = .midPurple

        let subtitle = UILabel()
        subtitle.text = "Pick one chest. Premium boosts are powered by Gems."
        subtitle.font = .rounded(size: 13, weight: .medium)
        subtitle.textColor = .textSecondary
        subtitle.numberOfLines = 2
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.minimumScaleFactor = 0.78

        let balance = UILabel()
        balance.font = .rounded(size: 15, weight: .black)
        balance.textColor = .accentCyan
        balance.textAlignment = .right
        gemsLabel = balance

        chestStack.axis = .horizontal
        chestStack.spacing = 8
        chestStack.distribution = .fillEqually
        for index in 0..<3 {
            let button = makeChestButton(index: index)
            chestButtons.append(button)
            chestStack.addArrangedSubview(button)
        }

        let doubleBadge = PaddingLabel()
        doubleBadge.font = .rounded(size: 11, weight: .black)
        doubleBadge.textColor = .accentOrange
        doubleBadge.backgroundColor = UIColor.accentOrange.withAlphaComponent(0.12)
        doubleBadge.layer.cornerRadius = 10
        doubleBadge.layer.masksToBounds = true
        doubleBadge.insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        doubleBadge.textAlignment = .center
        doubleBadge.tag = 2001
        self.doubleBadge = doubleBadge

        let status = UILabel()
        status.font = .rounded(size: 13, weight: .medium)
        status.textColor = .textSecondary
        status.textAlignment = .left
        status.numberOfLines = 2
        bonusStatusLabel = status

        rerollButton.addAction(UIAction { [weak self] _ in
            self?.rerollChests()
        }, for: .touchUpInside)

        card.addSubview(title)
        card.addSubview(balance)
        card.addSubview(subtitle)
        card.addSubview(chestStack)
        card.addSubview(doubleBadge)
        card.addSubview(status)
        card.addSubview(rerollButton)

        title.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(balance.snp.leading).offset(-8)
        }
        balance.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(title)
            make.width.equalTo(84)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(title.snp.bottom).offset(5)
        }
        chestStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(subtitle.snp.bottom).offset(14)
            make.height.equalTo(76)
        }
        doubleBadge.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(chestStack.snp.bottom).offset(10)
            make.height.equalTo(22)
        }
        rerollButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(doubleBadge.snp.bottom).offset(8)
            make.leading.equalTo(title)
            make.height.equalTo(44)
        }
        status.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(rerollButton.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-14)
        }
        card.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(278)
        }
        return card
    }

    private func makeChestButton(index: Int) -> UIControl {
        let button = UIControl()
        button.backgroundColor = UIColor.accentOrange.withAlphaComponent(0.12)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.accentOrange.withAlphaComponent(0.38).cgColor
        button.addPressAnimation()

        let icon = UILabel()
        icon.text = "?"
        icon.font = .rounded(size: 28, weight: .black)
        icon.textColor = .accentOrange
        icon.textAlignment = .center

        let value = UILabel()
        value.font = .rounded(size: 12, weight: .black)
        value.textColor = .midPurple
        value.textAlignment = .center
        value.text = "CHEST \(index + 1)"
        chestValueLabels.append(value)

        let stack = UIStackView(arrangedSubviews: [icon, value])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        button.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(4)
        }
        button.addAction(UIAction { [weak self] _ in
            self?.claimChest(index: index)
        }, for: .touchUpInside)
        return button
    }

    private func updateTreasureBonusUI() {
        guard viewModel.isTreasureBonus else { return }
        gemsLabel?.text = Formatters.gems(viewModel.gems)
        doubleBadge?.text = viewModel.hasDoubleTreasure ? "2X TREASURE ACTIVE" : "2X TREASURE IN STORE"
        doubleBadge?.textColor = viewModel.hasDoubleTreasure ? .white : .accentOrange
        doubleBadge?.backgroundColor = viewModel.hasDoubleTreasure ? .accentOrange : UIColor.accentOrange.withAlphaComponent(0.12)

        if let selectedChest = viewModel.selectedChest {
            chestValueLabels.enumerated().forEach { index, label in
                label.text = index == selectedChest
                    ? "+\(Formatters.integer.string(from: NSNumber(value: viewModel.claimedReward ?? viewModel.chestRewards[index])) ?? "\(viewModel.claimedReward ?? viewModel.chestRewards[index])")"
                    : "LOCKED"
                label.textColor = index == selectedChest ? .success : .locked
            }
            bonusStatusLabel?.text = "Treasure claimed. Return to the game when you are ready."
        } else {
            chestValueLabels.enumerated().forEach { index, label in
                label.text = "CHEST \(index + 1)"
                label.textColor = .midPurple
                chestButtons[index].isEnabled = true
                chestButtons[index].alpha = 1
            }
            bonusStatusLabel?.text = viewModel.hasDoubleTreasure
                ? "Double Treasure will multiply your selected chest."
                : "Pick a chest or redeem a premium boost in the Gems Store."
        }
        if let selectedChest = viewModel.selectedChest {
            chestButtons.enumerated().forEach { index, button in
                button.isEnabled = false
                button.alpha = index == selectedChest ? 1 : 0.5
            }
        }
        rerollButton.title = viewModel.selectedChest != nil
            ? (viewModel.canStartNextPick ? "USE PICK TICKET" : "GET PICK TICKET")
            : (viewModel.canReroll ? "REROLL READY" : "GET REROLL")
        rerollButton.setEnabled(true)
    }

    private func claimChest(index: Int) {
        guard let result = viewModel.claimChest(at: index) else { return }
        updateTreasureBonusUI()
        GameFeedback.reward()
        let multiplierText = result.wasDoubled ? " 2x boost applied." : ""
        showMessage(
            title: "Treasure Found",
            message: "+\(result.coinsAwarded) Coins awarded.\(multiplierText)"
        )
    }

    private func rerollChests() {
        if viewModel.selectedChest != nil, viewModel.startNextPick() {
            updateTreasureBonusUI()
            return
        }
        guard viewModel.selectedChest == nil, viewModel.reroll() else {
            let needsPick = viewModel.selectedChest != nil
            let alert = UIAlertController(
                title: needsPick ? "Pick Ticket Required" : "Reroll Unavailable",
                message: needsPick ? "Redeem a Bonus Pick Ticket in the Points Store to open another chest." : "Redeem Treasure Reroll in the Gems Store first.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "CANCEL", style: .cancel))
            alert.addAction(UIAlertAction(title: "OPEN STORE", style: .default) { [weak self] _ in
                guard let self else { return }
                let openStore = self.onOpenStore
                self.dismiss(animated: true) { openStore(needsPick ? .points : .gems) }
            })
            present(alert, animated: true)
            return
        }
        updateTreasureBonusUI()
        showMessage(title: "Chests Rerolled", message: "A fresh set of treasure rewards is ready.")
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func makePayRow(symbol: SlotSymbol, payout: String) -> UIView {
        let row = UIView()
        if symbol == .seven {
            row.backgroundColor = UIColor(hex: "#FEF3D8")
            row.layer.cornerRadius = 12
        }
        let symbols = UIStackView()
        symbols.axis = .horizontal
        symbols.spacing = 4
        for _ in 0..<3 {
            let gradient: CAGradientLayer?
            if symbol == .diamond {
                gradient = PrototypeGradient.cyan()
            } else if symbol == .seven {
                gradient = PrototypeGradient.seven()
            } else if symbol == .star {
                gradient = .goldGradient()
            } else {
                gradient = nil
            }
            symbols.addArrangedSubview(SymbolTile(symbol: symbol, gradient: gradient, cornerRadius: 7, fontSize: 24))
        }
        let value = UILabel()
        value.text = payout
        value.font = .rounded(size: 17, weight: .black)
        value.textColor = symbol == .seven ? UIColor(hex: "#B45309") : .midPurple
        value.textAlignment = .right

        row.addSubview(symbols)
        row.addSubview(value)
        symbols.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(26)
        }
        symbols.arrangedSubviews.forEach { view in
            view.snp.makeConstraints { make in
                make.width.height.equalTo(26)
            }
        }
        value.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(symbols.snp.trailing).offset(12)
        }
        row.snp.makeConstraints { make in
            make.height.equalTo(34)
        }
        return row
    }

    private func makeCTA() -> UIView {
        let container = UIView()
        let button = UIControl()
        let buttonBackground = GradientView(gradient: PrototypeGradient.goldPink(), cornerRadius: 25)
        let buttonTitle = UILabel()
        buttonTitle.text = "BACK TO GAME  →"
        button.accessibilityIdentifier = "bonus.backToGame"
        button.accessibilityLabel = "Back to game"
        buttonBackground.isUserInteractionEnabled = false
        buttonTitle.font = .rounded(size: 17, weight: .black)
        buttonTitle.textColor = .white
        buttonTitle.textAlignment = .center
        buttonTitle.adjustsFontSizeToFitWidth = true
        buttonTitle.minimumScaleFactor = 0.75

        let caption = UILabel()
        caption.text = "Continue playing \(viewModel.game.title)"
        caption.font = .caption
        caption.textColor = .textSecondary
        caption.textAlignment = .center

        button.addSubview(buttonBackground)
        buttonBackground.addSubview(buttonTitle)
        container.addSubview(button)
        container.addSubview(caption)
        button.applySoftShadow()
        button.addPressAnimation()

        buttonBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        buttonTitle.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18))
        }
        button.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        caption.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        container.snp.makeConstraints { make in
            make.height.equalTo(70)
        }
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: true)
        }, for: .touchUpInside)
        return container
    }
}
