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
        label.font = .rounded(size: symbol == .bar ? fontSize * 0.52 : fontSize, weight: .black)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.65
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

    init(amount: Int, dark: Bool = false) {
        super.init(frame: .zero)
        setup(dark: dark)
        configure(amount: amount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(dark: Bool) {
        backgroundColor = dark ? .brandGold : UIColor.white.withAlphaComponent(0.96)
        layer.cornerCurve = .continuous
        layer.borderWidth = dark ? 0 : 1.5
        layer.borderColor = UIColor.brandGold.cgColor

        label.font = .rounded(size: 17, weight: .black)
        label.textColor = dark ? .white : .midPurple
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
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
        case .me: return "●"
        case .more: return "≡"
        }
    }
}

final class LobbySlotRowView: UIControl {
    private let iconTile = UIView()
    private let titleLabel = UILabel()
    private let tagLabel = PaddingLabel()
    private let subtitleLabel = UILabel()
    private let arrow = CircleButton(text: ">", size: 48, background: .brandPink, tint: .white)

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
        applySoftShadow()
        arrow.isUserInteractionEnabled = false

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

        addSubview(iconTile)
        addSubview(titleLabel)
        addSubview(tagLabel)
        addSubview(subtitleLabel)
        addSubview(arrow)

        iconTile.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(72)
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconTile.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-12)
        }
        tagLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-12)
            make.height.equalTo(22)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-12)
            make.top.equalTo(tagLabel.snp.bottom).offset(5)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
        snp.makeConstraints { make in
            make.height.equalTo(108)
        }
        addPressAnimation()
    }

    func configure(game: SlotGame, tag: String, tagColor: UIColor, tagBackground: UIColor) {
        iconTile.subviews.forEach { $0.removeFromSuperview() }
        let symbol = game.symbolSet.first ?? .seven
        let tile = SymbolTile(symbol: symbol, gradient: symbol == .diamond ? PrototypeGradient.cyan() : PrototypeGradient.seven(), cornerRadius: 22, fontSize: 54)
        iconTile.addSubview(tile)
        tile.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        titleLabel.text = game.title
        tagLabel.text = tag
        tagLabel.textColor = tagColor
        tagLabel.backgroundColor = tagBackground
        subtitleLabel.text = game.subtitle.replacingOccurrences(of: " · ", with: "  •  ")
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
