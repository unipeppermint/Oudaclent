import UIKit

final class PrototypeBackgroundView: UIView {
    private let gradient: CAGradientLayer

    init(style: Style) {
        gradient = style == .game ? PrototypeGradient.gameBackground() : PrototypeGradient.lightBackground()
        super.init(frame: .zero)
        layer.insertSublayer(gradient, at: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Style {
        case light, game
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}

final class CircleButton: UIButton {
    init(symbolName: String? = nil, text: String? = nil, size: CGFloat = 40, background: UIColor = .white, tint: UIColor = .brandPink) {
        super.init(frame: .zero)
        backgroundColor = background
        layer.cornerRadius = size / 2
        setTitle(text, for: .normal)
        setTitleColor(tint, for: .normal)
        titleLabel?.font = .rounded(size: size < 50 ? 21 : 26, weight: .black)
        tintColor = tint
        if let symbolName {
            setImage(UIImage(systemName: symbolName), for: .normal)
        }
        applySoftShadow()
        addPressAnimation()
        snp.makeConstraints { make in
            make.width.height.equalTo(size)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SymbolTile: UIView {
    private let gradientView: GradientView?
    private let label = UILabel()

    init(symbol: SlotSymbol, gradient: CAGradientLayer? = nil, cornerRadius: CGFloat = 22, fontSize: CGFloat = 48) {
        if let gradient {
            self.gradientView = GradientView(gradient: gradient, cornerRadius: cornerRadius)
        } else {
            self.gradientView = nil
        }
        super.init(frame: .zero)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        backgroundColor = gradient == nil ? .white : .clear
        if let gradientView {
            addSubview(gradientView)
            gradientView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        label.text = symbol.display
        label.textAlignment = .center
        label.textColor = symbol == .seven ? .white : symbol.color
        label.font = .rounded(size: symbol == .bar ? fontSize * 0.38 : fontSize, weight: .black)
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.45
        addSubview(label)
        let labelInset = max(2, min(Spacing.xs, fontSize * 0.14))
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(labelInset)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PrototypeCoinBadge: UIView {
    private let label = UILabel()

    init(amount: Int, dark: Bool = false, fontSize: CGFloat = 17, horizontalInset: CGFloat = 10) {
        super.init(frame: .zero)
        setup(dark: dark, fontSize: fontSize, horizontalInset: horizontalInset)
        configure(amount: amount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(dark: Bool, fontSize: CGFloat, horizontalInset: CGFloat) {
        backgroundColor = dark ? .brandGold : UIColor.white.withAlphaComponent(0.96)
        layer.cornerCurve = .continuous
        layer.borderWidth = dark ? 0 : 1.5
        layer.borderColor = UIColor.brandGold.cgColor

        label.font = .rounded(size: fontSize, weight: .black)
        label.textColor = dark ? .white : .midPurple
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset))
        }
    }

    func configure(amount: Int) {
        label.text = Formatters.coins(amount)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

final class FloatingTabBarView: UIView {
    private let stack = UIStackView()
    private var itemViews: [FloatingTabItemView] = []
    var onSelect: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        layer.cornerRadius = 34
        applyCardShadow()

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(5)
        }

        AppTab.allCases.enumerated().forEach { index, tab in
            let item = FloatingTabItemView(tab: tab, index: index)
            item.onTap = { [weak self] selected in self?.onSelect?(selected) }
            itemViews.append(item)
            stack.addArrangedSubview(item)
        }
        update(selectedIndex: 0, dark: false)
    }

    func update(selectedIndex: Int, dark: Bool) {
        backgroundColor = dark ? UIColor(hex: "#2C2663") : .white
        itemViews.enumerated().forEach { index, item in
            item.setSelected(index == selectedIndex, dark: dark)
        }
    }
}

private final class FloatingTabItemView: UIControl {
    private let selectedBackground = GradientView(gradient: PrototypeGradient.pinkPurple(), cornerRadius: 31)
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let tab: AppTab
    private let index: Int
    var onTap: ((Int) -> Void)?

    init(tab: AppTab, index: Int) {
        self.tab = tab
        self.index = index
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        selectedBackground.isHidden = true
        addSubview(selectedBackground)
        selectedBackground.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconLabel.font = .rounded(size: 24, weight: .bold)
        iconLabel.textAlignment = .center
        titleLabel.font = .tabLabel
        titleLabel.textAlignment = .center
        titleLabel.text = tab.rawValue

        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 1
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onTap?(self.index)
        }, for: .touchUpInside)
        addPressAnimation()
    }

    func setSelected(_ selected: Bool, dark: Bool) {
        selectedBackground.isHidden = !selected
        let activeColor = UIColor.white
        let inactiveColor = dark ? UIColor(hex: "#9F83E8") : UIColor(hex: "#9CA3AF")
        iconLabel.textColor = selected ? activeColor : inactiveColor
        titleLabel.textColor = selected ? activeColor : (dark ? UIColor(hex: "#9F83E8") : UIColor(hex: "#6B7280"))
        titleLabel.font = selected ? .rounded(size: 10, weight: .black) : .tabLabel
        iconLabel.text = icon
    }

    private var icon: String {
        switch tab {
        case .lobby: return "▦"
        case .game: return "◆"
        case .rewards: return "★"
        case .me: return "●"
        }
    }
}

final class LobbySlotRowView: UIControl {
    private let iconTile = UIView()
    private let titleLabel = UILabel()
    private let tagLabel = PaddingLabel()
    private let subtitleLabel = UILabel()
    private let jackpotLabel = UILabel()
    private let metaStack = UIStackView()
    private let featureStack = UIStackView()
    private let symbolStack = UIStackView()
    private let playButton = UIView()
    private let playLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        applySoftShadow()

        titleLabel.font = .rounded(size: 24, weight: .black)
        titleLabel.textColor = .midPurple
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.78
        tagLabel.font = .rounded(size: 12, weight: .black)
        tagLabel.layer.cornerRadius = 11
        tagLabel.layer.masksToBounds = true
        tagLabel.adjustsFontSizeToFitWidth = true
        tagLabel.minimumScaleFactor = 0.74
        subtitleLabel.font = .body
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.78
        subtitleLabel.numberOfLines = 1

        jackpotLabel.font = .rounded(size: 13, weight: .black)
        jackpotLabel.textColor = UIColor(hex: "#B45309")
        jackpotLabel.textAlignment = .right
        jackpotLabel.adjustsFontSizeToFitWidth = true
        jackpotLabel.minimumScaleFactor = 0.72

        metaStack.axis = .horizontal
        metaStack.spacing = 6
        metaStack.distribution = .fillEqually
        metaStack.isUserInteractionEnabled = false

        featureStack.axis = .horizontal
        featureStack.spacing = 6
        featureStack.alignment = .fill
        featureStack.distribution = .fillEqually
        featureStack.isUserInteractionEnabled = false

        symbolStack.axis = .horizontal
        symbolStack.spacing = 5
        symbolStack.alignment = .center
        symbolStack.isUserInteractionEnabled = false

        playButton.backgroundColor = .brandPink
        playButton.layer.cornerRadius = 18
        playButton.layer.cornerCurve = .continuous
        playButton.isUserInteractionEnabled = false
        playLabel.text = "PLAY"
        playLabel.font = .rounded(size: 13, weight: .black)
        playLabel.textColor = .white
        playLabel.textAlignment = .center

        addSubview(iconTile)
        addSubview(titleLabel)
        addSubview(tagLabel)
        addSubview(subtitleLabel)
        addSubview(jackpotLabel)
        addSubview(metaStack)
        addSubview(featureStack)
        addSubview(symbolStack)
        addSubview(playButton)
        playButton.addSubview(playLabel)

        iconTile.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(72)
        }
        jackpotLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.top.equalToSuperview().offset(18)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconTile.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(jackpotLabel.snp.leading).offset(-8)
        }
        tagLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.trailing.lessThanOrEqualTo(jackpotLabel)
            make.height.equalTo(22)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.top.equalTo(tagLabel.snp.bottom).offset(5)
        }
        metaStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(iconTile.snp.bottom).offset(10)
            make.height.equalTo(34)
        }
        featureStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(metaStack)
            make.top.equalTo(metaStack.snp.bottom).offset(7)
            make.height.equalTo(28)
        }
        symbolStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalTo(featureStack.snp.bottom).offset(8)
            make.height.equalTo(28)
        }
        symbolStack.arrangedSubviews.forEach { view in
            view.snp.makeConstraints { make in
                make.width.height.equalTo(28)
            }
        }
        playButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalTo(symbolStack)
            make.width.equalTo(66)
            make.height.equalTo(36)
            make.leading.greaterThanOrEqualTo(symbolStack.snp.trailing).offset(12)
        }
        playLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8))
        }
        snp.makeConstraints { make in
            make.height.equalTo(226)
        }
        addPressAnimation()
    }

    func configure(game: SlotGame, tag: String, tagColor: UIColor, tagBackground: UIColor) {
        iconTile.subviews.forEach { $0.removeFromSuperview() }
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        featureStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        symbolStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let symbol = game.symbolSet.first ?? .seven
        let tile = SymbolTile(symbol: symbol, gradient: gradient(for: symbol, theme: game.theme), cornerRadius: 22, fontSize: 54)
        iconTile.addSubview(tile)
        tile.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.text = game.title
        tagLabel.text = tag
        tagLabel.textColor = tagColor
        tagLabel.backgroundColor = tagBackground
        subtitleLabel.text = game.subtitle.replacingOccurrences(of: " · ", with: "  •  ")
        jackpotLabel.text = "JP \(Formatters.integer.string(from: NSNumber(value: game.jackpotPool)) ?? "\(game.jackpotPool)")"

        [
            ("Reels", "\(game.reels)"),
            ("Lines", "\(game.paylines)"),
            ("Min Bet", "\(game.minBet)")
        ].forEach { item in
            metaStack.addArrangedSubview(makeMetaPill(title: item.0, value: item.1))
        }

        game.features.prefix(3).forEach { feature in
            featureStack.addArrangedSubview(makeFeaturePill(feature.title))
        }

        game.symbolSet.prefix(5).forEach { symbol in
            let tile = SymbolTile(symbol: symbol, gradient: gradient(for: symbol, theme: game.theme), cornerRadius: 8, fontSize: 22)
            symbolStack.addArrangedSubview(tile)
            tile.snp.makeConstraints { make in
                make.width.height.equalTo(28)
            }
        }
    }

    private func makeMetaPill(title: String, value: String) -> UIView {
        let pill = UIView()
        pill.backgroundColor = UIColor(hex: "#F8FAFC")
        pill.layer.cornerRadius = 12
        pill.layer.cornerCurve = .continuous

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .rounded(size: 14, weight: .black)
        valueLabel.textColor = .midPurple
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.72

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 9, weight: .semibold)
        titleLabel.textColor = .textSecondary
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 0
        stack.isUserInteractionEnabled = false
        pill.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(4)
        }
        return pill
    }

    private func makeFeaturePill(_ title: String) -> UIView {
        let pill = PaddingLabel()
        pill.text = title
        pill.textAlignment = .center
        pill.font = .rounded(size: 10, weight: .black)
        pill.textColor = .midPurple
        pill.backgroundColor = UIColor(hex: "#F1E8FF")
        pill.layer.cornerRadius = 14
        pill.layer.cornerCurve = .continuous
        pill.layer.masksToBounds = true
        pill.adjustsFontSizeToFitWidth = true
        pill.minimumScaleFactor = 0.68
        pill.insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        return pill
    }

    private func gradient(for symbol: SlotSymbol, theme: SlotTheme) -> CAGradientLayer? {
        switch symbol {
        case .seven:
            return PrototypeGradient.seven()
        case .star:
            return .goldGradient()
        case .diamond:
            return PrototypeGradient.cyan()
        case .bar:
            return theme == .treasure ? PrototypeGradient.goldPink() : nil
        case .cherry:
            return theme == .candy ? PrototypeGradient.pinkPurple() : nil
        }
    }
}

final class LobbySlotCardView: UIControl {
    private let hero = UIView()
    private let tagLabel = PaddingLabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let jackpotLabel = UILabel()
    private let metaStack = UIStackView()
    private let featureStack = UIStackView()
    private let playButton = UIView()
    private let playLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .white
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        applyCardShadow()
        addPressAnimation()

        hero.layer.cornerRadius = 24
        hero.layer.cornerCurve = .continuous
        hero.layer.masksToBounds = true

        tagLabel.font = .rounded(size: 11, weight: .black)
        tagLabel.layer.cornerRadius = 11
        tagLabel.layer.masksToBounds = true
        tagLabel.adjustsFontSizeToFitWidth = true
        tagLabel.minimumScaleFactor = 0.7

        titleLabel.font = .rounded(size: 22, weight: .black)
        titleLabel.textColor = .midPurple
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.74

        subtitleLabel.font = .caption
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.numberOfLines = 2
        subtitleLabel.adjustsFontSizeToFitWidth = true
        subtitleLabel.minimumScaleFactor = 0.76

        jackpotLabel.font = .rounded(size: 15, weight: .black)
        jackpotLabel.textColor = UIColor(hex: "#B45309")
        jackpotLabel.adjustsFontSizeToFitWidth = true
        jackpotLabel.minimumScaleFactor = 0.7

        metaStack.axis = .horizontal
        metaStack.spacing = 6
        metaStack.distribution = .fillEqually
        metaStack.isUserInteractionEnabled = false

        featureStack.axis = .horizontal
        featureStack.spacing = 6
        featureStack.distribution = .fillEqually
        featureStack.isUserInteractionEnabled = false

        playButton.backgroundColor = .brandGold
        playButton.layer.cornerRadius = 22
        playButton.layer.cornerCurve = .continuous
        playButton.isUserInteractionEnabled = false
        playLabel.text = "PLAY"
        playLabel.textColor = .deepPurple
        playLabel.textAlignment = .center
        playLabel.font = .rounded(size: 15, weight: .black)

        addSubview(hero)
        hero.addSubview(tagLabel)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(jackpotLabel)
        addSubview(metaStack)
        addSubview(featureStack)
        addSubview(playButton)
        playButton.addSubview(playLabel)

        hero.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(150)
        }
        tagLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
            make.height.equalTo(22)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(hero.snp.bottom).offset(10)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
        jackpotLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(5)
            make.height.equalTo(18)
        }
        metaStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(jackpotLabel.snp.bottom).offset(8)
            make.height.equalTo(32)
        }
        featureStack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(metaStack.snp.bottom).offset(8)
            make.height.equalTo(26)
        }
        playButton.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(42)
        }
        playLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14))
        }
    }

    func configure(game: SlotGame, tag: String, tagColor: UIColor, tagBackground: UIColor) {
        hero.subviews.filter { $0 !== tagLabel }.forEach { $0.removeFromSuperview() }
        metaStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        featureStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let background = GradientView(gradient: game.theme.gradient, cornerRadius: 24)
        hero.insertSubview(background, at: 0)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tagLabel.text = tag
        tagLabel.textColor = tagColor
        tagLabel.backgroundColor = tagBackground
        titleLabel.text = game.title
        subtitleLabel.text = game.subtitle.replacingOccurrences(of: " · ", with: "  •  ")
        jackpotLabel.text = "JP \(Formatters.integer.string(from: NSNumber(value: game.jackpotPool)) ?? "\(game.jackpotPool)")"

        let symbolStack = UIStackView()
        symbolStack.axis = .horizontal
        symbolStack.spacing = 8
        symbolStack.alignment = .center
        symbolStack.distribution = .equalCentering
        symbolStack.isUserInteractionEnabled = false
        hero.addSubview(symbolStack)
        symbolStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(14)
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.height.equalTo(78)
        }

        game.symbolSet.prefix(3).enumerated().forEach { index, symbol in
            let size: CGFloat = index == 1 ? 78 : 62
            let tile = SymbolTile(symbol: symbol, gradient: gradient(for: symbol, theme: game.theme), cornerRadius: 18, fontSize: index == 1 ? 43 : 34)
            symbolStack.addArrangedSubview(tile)
            tile.snp.makeConstraints { make in
                make.width.height.equalTo(size)
            }
        }

        [
            ("Reels", "\(game.reels)"),
            ("Lines", "\(game.paylines)"),
            ("Min Bet", "\(game.minBet)")
        ].forEach { item in
            metaStack.addArrangedSubview(makeMetaPill(title: item.0, value: item.1))
        }

        game.features.prefix(3).forEach { feature in
            featureStack.addArrangedSubview(makeFeaturePill(feature.title))
        }
    }

    private func makeMetaPill(title: String, value: String) -> UIView {
        let pill = UIView()
        pill.backgroundColor = UIColor(hex: "#F8FAFC")
        pill.layer.cornerRadius = 12
        pill.layer.cornerCurve = .continuous

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .rounded(size: 14, weight: .black)
        valueLabel.textColor = .midPurple
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.72

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 9, weight: .semibold)
        titleLabel.textColor = .textSecondary
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 0
        stack.isUserInteractionEnabled = false
        pill.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(4)
        }
        return pill
    }

    private func makeFeaturePill(_ title: String) -> UIView {
        let pill = PaddingLabel()
        pill.text = title
        pill.textAlignment = .center
        pill.font = .rounded(size: 10, weight: .black)
        pill.textColor = .midPurple
        pill.backgroundColor = UIColor(hex: "#F1E8FF")
        pill.layer.cornerRadius = 14
        pill.layer.cornerCurve = .continuous
        pill.layer.masksToBounds = true
        pill.adjustsFontSizeToFitWidth = true
        pill.minimumScaleFactor = 0.68
        pill.insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        return pill
    }

    private func gradient(for symbol: SlotSymbol, theme: SlotTheme) -> CAGradientLayer? {
        switch symbol {
        case .seven:
            return PrototypeGradient.seven()
        case .star:
            return .goldGradient()
        case .diamond:
            return PrototypeGradient.cyan()
        case .bar:
            return theme == .treasure ? PrototypeGradient.goldPink() : nil
        case .cherry:
            return theme == .candy ? PrototypeGradient.pinkPurple() : nil
        }
    }
}

final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
