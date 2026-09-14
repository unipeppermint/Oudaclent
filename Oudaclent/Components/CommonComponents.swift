import UIKit

final class CoinBadge: UIView {
    private let backgroundView = GradientView(gradient: .brandGradient(), cornerRadius: Radius.pill)
    private let label = UILabel()

    init(amount: Int) {
        super.init(frame: .zero)
        setup()
        configure(amount: amount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(36)
        }

        label.font = .bodyBold
        label.textColor = .white
        label.textAlignment = .center
        backgroundView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: Spacing.md, bottom: 0, right: Spacing.md))
        }
    }

    func configure(amount: Int) {
        label.text = Formatters.coins(amount)
    }
}

final class PrimaryButton: UIControl {
    private let backgroundView: GradientView
    private let label = UILabel()

    var title: String {
        get { label.text ?? "" }
        set { label.text = newValue }
    }

    init(title: String, gradient: CAGradientLayer = .goldGradient()) {
        self.backgroundView = GradientView(gradient: gradient, cornerRadius: Radius.pill)
        super.init(frame: .zero)
        setup()
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundView.isUserInteractionEnabled = false
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.greaterThanOrEqualTo(44)
        }
        label.font = .button
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.78
        backgroundView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: Spacing.lg, bottom: 0, right: Spacing.lg))
        }
        applySoftShadow()
        addPressAnimation()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 1 : 0.5
    }
}

final class GradientCard: UIView {
    private let backgroundView: GradientView

    init(gradient: CAGradientLayer, cornerRadius: CGFloat = Radius.large) {
        self.backgroundView = GradientView(gradient: gradient, cornerRadius: cornerRadius)
        super.init(frame: .zero)
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        applyCardShadow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TopBarView: UIView {
    private let titleLabel = UILabel()
    private let leftContainer = UIView()
    private let rightContainer = UIView()

    init(title: String? = nil) {
        super.init(frame: .zero)
        setup()
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel.font = .h2
        titleLabel.textColor = .textPrimary
        titleLabel.textAlignment = .center

        addSubview(leftContainer)
        addSubview(titleLabel)
        addSubview(rightContainer)

        leftContainer.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.height.equalTo(44)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.42)
        }
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(leftContainer.snp.trailing).offset(Spacing.sm)
            make.trailing.lessThanOrEqualTo(rightContainer.snp.leading).offset(-Spacing.sm)
        }
        rightContainer.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.height.equalTo(44)
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.42)
        }
    }

    func setLeft(_ view: UIView?) {
        leftContainer.subviews.forEach { $0.removeFromSuperview() }
        guard let view else { return }
        leftContainer.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setRight(_ view: UIView?) {
        rightContainer.subviews.forEach { $0.removeFromSuperview() }
        guard let view else { return }
        rightContainer.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

final class SymbolBadgeView: UIView {
    private let label = UILabel()

    init(symbol: SlotSymbol, size: CGFloat = 60) {
        super.init(frame: .zero)
        layer.cornerRadius = Radius.medium
        layer.masksToBounds = true
        backgroundColor = symbol.color.withAlphaComponent(0.12)
        label.text = symbol.display
        label.textColor = symbol.color
        label.font = .rounded(size: symbol == .bar ? 21 : 30, weight: .black)
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Spacing.xs)
            make.width.height.greaterThanOrEqualTo(size - 16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CheckInBannerView: UIView {
    private let card = GradientView(gradient: .brandGradient(), cornerRadius: Radius.large)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dotsStack = UIStackView()
    private let goButton = PrimaryButton(title: "GO")
    private var onCheckIn: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.font = .h3
        titleLabel.textColor = .white
        subtitleLabel.font = .caption
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        subtitleLabel.numberOfLines = 2

        dotsStack.axis = .horizontal
        dotsStack.spacing = Spacing.xs
        dotsStack.distribution = .fillEqually

        goButton.addAction(UIAction { [weak self] _ in
            self?.onCheckIn?()
        }, for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, dotsStack])
        textStack.axis = .vertical
        textStack.spacing = Spacing.xs

        card.addSubview(textStack)
        card.addSubview(goButton)

        textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.lg)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(goButton.snp.leading).offset(-Spacing.md)
        }
        goButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.lg)
            make.centerY.equalToSuperview()
            make.width.equalTo(72)
            make.height.equalTo(40)
        }
    }

    func configure(
        streak: Int,
        canCheckIn: Bool = true,
        nextReward: (coins: Int, gems: Int)? = nil,
        onCheckIn: (() -> Void)? = nil
    ) {
        self.onCheckIn = onCheckIn
        let reward = nextReward ?? (coins: 1_000, gems: 1)
        titleLabel.text = canCheckIn ? "Daily Check-in" : "Checked In Today"
        subtitleLabel.text = canCheckIn
            ? "Day \(min(7, max(1, streak)))/7  •  +\(reward.coins) Coins  +\(reward.gems) Gems"
            : "Come back tomorrow  •  \(streak)-day streak"
        goButton.title = canCheckIn ? "CLAIM" : "DONE"
        goButton.setEnabled(canCheckIn)
        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for index in 1...7 {
            let dot = UIView()
            dot.layer.cornerRadius = 5
            dot.backgroundColor = index <= streak ? .brandGold : UIColor.white.withAlphaComponent(0.35)
            dotsStack.addArrangedSubview(dot)
            dot.snp.makeConstraints { make in
                make.height.equalTo(10)
            }
        }
    }
}

final class SlotCardView: UIView {
    private let content = UIView()
    private var hero = GradientView(gradient: .brandGradient(), cornerRadius: Radius.large)
    private let symbolLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let playButton = PrimaryButton(title: "PLAY")
    private var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        content.backgroundColor = .bgCard
        content.layer.cornerRadius = Radius.large
        content.layer.masksToBounds = true
        addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        applyCardShadow()

        symbolLabel.font = .rounded(size: 88, weight: .black)
        symbolLabel.textAlignment = .center
        symbolLabel.textColor = .white

        titleLabel.font = .h2
        titleLabel.textColor = .textPrimary
        subtitleLabel.font = .caption
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.numberOfLines = 2

        content.addSubview(hero)
        hero.addSubview(symbolLabel)
        content.addSubview(titleLabel)
        content.addSubview(subtitleLabel)
        content.addSubview(playButton)

        hero.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(220)
        }
        symbolLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(hero.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.lg)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.xs)
            make.leading.trailing.equalTo(titleLabel)
        }
        playButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-Spacing.lg)
            make.height.equalTo(44)
        }
        playButton.addAction(UIAction { [weak self] _ in self?.onTap?() }, for: .touchUpInside)
    }

    func configure(game: SlotGame, onTap: (() -> Void)?) {
        self.onTap = onTap
        hero.removeFromSuperview()
        hero = GradientView(gradient: game.theme.gradient, cornerRadius: Radius.large)
        content.insertSubview(hero, at: 0)
        hero.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(Spacing.md)
            make.height.equalTo(220)
        }
        hero.addSubview(symbolLabel)
        symbolLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(hero.snp.bottom).offset(Spacing.md)
            make.leading.trailing.equalToSuperview().inset(Spacing.lg)
        }
        symbolLabel.text = game.symbolSet.first?.display ?? "★"
        titleLabel.text = game.title
        subtitleLabel.text = game.subtitle
    }
}

final class SlotCardCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "SlotCardCollectionViewCell"
    private let card = SlotCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 12, right: 0))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(game: SlotGame, onTap: (() -> Void)?) {
        card.configure(game: game, onTap: onTap)
    }
}

final class FeatureCardView: UIView {
    private let iconCircle = GradientView(gradient: .brandGradient(), cornerRadius: 30)
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .bgCard
        layer.cornerRadius = Radius.medium
        applySoftShadow()

        titleLabel.font = .h3
        titleLabel.textColor = .textPrimary
        descLabel.font = .caption
        descLabel.textColor = .textSecondary
        descLabel.numberOfLines = 2
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        addSubview(iconCircle)
        iconCircle.addSubview(iconView)
        addSubview(titleLabel)
        addSubview(descLabel)

        iconCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.lg)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(60)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(26)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconCircle.snp.trailing).offset(Spacing.md)
            make.trailing.equalToSuperview().offset(-Spacing.lg)
            make.top.equalToSuperview().offset(Spacing.lg)
        }
        descLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.xxs)
        }
    }

    func configure(icon: String, title: String, desc: String) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        descLabel.text = desc
    }
}

final class PayTableRowView: UIView {
    private let symbolLabel = UILabel()
    private let descLabel = UILabel()
    private let multiplierLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        symbolLabel.font = .h3
        symbolLabel.textAlignment = .center
        descLabel.font = .body
        descLabel.textColor = .textPrimary
        multiplierLabel.font = .bodyBold
        multiplierLabel.textColor = .accentOrange
        multiplierLabel.textAlignment = .right

        addSubview(symbolLabel)
        addSubview(descLabel)
        addSubview(multiplierLabel)

        symbolLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(92)
        }
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(symbolLabel.snp.trailing).offset(Spacing.sm)
            make.centerY.equalToSuperview()
        }
        multiplierLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(descLabel.snp.trailing).offset(Spacing.sm)
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(60)
        }
        snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    func configure(symbol: String, desc: String, multiplier: Int) {
        symbolLabel.text = symbol
        descLabel.text = desc
        multiplierLabel.text = "x\(multiplier)"
    }
}
