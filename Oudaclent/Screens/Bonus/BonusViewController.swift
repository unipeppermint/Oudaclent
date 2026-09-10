import UIKit

final class BonusViewController: BaseViewController {
    private let viewModel: BonusViewModel
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(game: SlotGame) {
        self.viewModel = BonusViewModel(game: game)
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
        contentStack.addArrangedSubview(makeHero())
        contentStack.addArrangedSubview(makeFeatureRow())
        contentStack.addArrangedSubview(makePayTable())
        contentStack.addArrangedSubview(makeCTA())
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let back = CircleButton(text: "<", size: 40, background: .white, tint: .midPurple)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        let title = UILabel()
        title.text = "\(viewModel.game.title) Features"
        title.font = .rounded(size: 24, weight: .black)
        title.textColor = .midPurple
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.72
        let heart = CircleButton(text: "♥", size: 40, background: .white, tint: .warning)

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
        buttonTitle.text = "PLAY NOW  →"
        buttonTitle.font = .rounded(size: 17, weight: .black)
        buttonTitle.textColor = .white
        buttonTitle.textAlignment = .center
        buttonTitle.adjustsFontSizeToFitWidth = true
        buttonTitle.minimumScaleFactor = 0.75

        let caption = UILabel()
        caption.text = "Min Bet \(viewModel.game.minBet)  •  \(viewModel.game.reels) Reels  •  \(viewModel.game.paylines) Lines"
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
            (self.tabBarController as? MainTabBarController)?.showGame(self.viewModel.game)
        }, for: .touchUpInside)
        return container
    }
}
