import UIKit

final class SlotReelView: UIView {
    private let stackView = UIStackView()
    private let symbolFontSize: CGFloat
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var duration: TimeInterval = 0
    private var targetSymbols: [SlotSymbol] = [.seven, .star, .diamond]
    private let symbolPool: [SlotSymbol]

    var onReelStopped: (() -> Void)?

    init(frame: CGRect = .zero, symbolFontSize: CGFloat = 43, symbols: [SlotSymbol] = SlotSymbol.allCases) {
        self.symbolFontSize = symbolFontSize
        self.symbolPool = (symbols.isEmpty ? SlotSymbol.allCases : symbols) + (symbols.isEmpty ? SlotSymbol.allCases : symbols)
        super.init(frame: frame)
        setup()
        render(symbols: Array(self.symbolPool.prefix(3)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        clipsToBounds = true
        layer.cornerRadius = 14
        backgroundColor = UIColor(hex: "#0E0B2D")
        stackView.axis = .vertical
        stackView.spacing = Spacing.xs
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Spacing.xs)
        }
    }

    private func render(symbols: [SlotSymbol]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        symbols.prefix(3).forEach { symbol in
            let badge = SymbolTile(symbol: symbol, gradient: tileGradient(for: symbol), cornerRadius: 12, fontSize: symbolFontSize)
            stackView.addArrangedSubview(badge)
        }
    }

    private func tileGradient(for symbol: SlotSymbol) -> CAGradientLayer? {
        switch symbol {
        case .seven: return PrototypeGradient.seven()
        case .star: return .goldGradient()
        case .diamond: return PrototypeGradient.cyan()
        case .cherry: return nil
        case .bar: return nil
        }
    }

    func show(symbols: [SlotSymbol]) {
        render(symbols: symbols)
    }

    func spin(to symbols: [SlotSymbol], duration: TimeInterval = 0.8) {
        displayLink?.invalidate()
        self.duration = duration
        self.targetSymbols = symbols
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func tick() {
        let elapsed = CACurrentMediaTime() - startTime
        let progress = min(1, elapsed / duration)
        if progress < 1 {
            let poolIndex = Int(elapsed * 18) % symbolPool.count
            let rolling = (0..<3).map { symbolPool[(poolIndex + $0) % symbolPool.count] }
            render(symbols: rolling)
            stackView.transform = CGAffineTransform(translationX: 0, y: CGFloat(sin(progress * .pi * 8)) * 6)
        } else {
            displayLink?.invalidate()
            displayLink = nil
            render(symbols: targetSymbols)
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.9) {
                self.stackView.transform = .identity
            } completion: { _ in
                self.onReelStopped?()
            }
        }
    }
}

final class SlotMachineGrid: UIView {
    private let reelStack = UIStackView()
    private let reels: [SlotReelView]
    private let symbols: [SlotSymbol]

    init(reelCount: Int = 3, symbols: [SlotSymbol] = SlotSymbol.allCases) {
        let clampedReelCount = max(3, min(5, reelCount))
        let normalizedSymbols = symbols.isEmpty ? SlotSymbol.allCases : symbols
        self.symbols = normalizedSymbols
        let symbolFontSize: CGFloat = clampedReelCount >= 5 ? 34 : 43
        self.reels = (0..<clampedReelCount).map { _ in
            SlotReelView(symbolFontSize: symbolFontSize, symbols: normalizedSymbols)
        }
        super.init(frame: .zero)
        setup()
    }

    override convenience init(frame: CGRect) {
        self.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = UIColor(hex: "#332B70")
        layer.cornerRadius = 24
        layer.borderColor = UIColor.brandGold.cgColor
        layer.borderWidth = 3
        applyGlowShadow(color: .brandGold)

        reelStack.axis = .horizontal
        reelStack.spacing = Spacing.sm
        reelStack.distribution = .fillEqually
        addSubview(reelStack)
        reelStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(15)
        }
        reels.forEach { reelStack.addArrangedSubview($0) }
        reels.enumerated().forEach { index, reel in
            reel.show(symbols: initialSymbols(for: index))
        }
    }

    func spinAll(_ result: [[SlotSymbol]], completion: @escaping () -> Void) {
        var stopped = 0
        for (index, reel) in reels.enumerated() {
            reel.onReelStopped = { [weak self] in
                guard let self else { return }
                stopped += 1
                if stopped == self.reels.count {
                    completion()
                }
            }
            let symbols = result.indices.contains(index) ? result[index] : Array(self.symbols.shuffled().prefix(3))
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                reel.spin(to: symbols, duration: 1.5)
            }
        }
    }

    private func initialSymbols(for index: Int) -> [SlotSymbol] {
        (0..<3).map { row in
            symbols[(index + row) % symbols.count]
        }
    }
}

final class SpinButton: UIButton {
    var isSpinning: Bool = false {
        didSet {
            isEnabled = !isSpinning
            alpha = isSpinning ? 0.7 : 1
            setTitle(isSpinning ? "..." : "GO!", for: .normal)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setTitle("GO!", for: .normal)
        setTitleColor(.deepPurple, for: .normal)
        titleLabel?.font = .rounded(size: 27, weight: .black)
        backgroundColor = .brandGold
        layer.cornerRadius = 44
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        applyGlowShadow(color: .brandGold)
        addPressAnimation()
    }
}

final class BetControl: UIView {
    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let betLabel = UILabel()

    var onChange: ((Int) -> Void)?
    var minimumBet: Int = 50 {
        didSet {
            bet = max(minimumBet, bet)
        }
    }
    var bet: Int = AppSettingsStore.shared.settings.betAmount {
        didSet {
            bet = max(minimumBet, min(500, bet))
            var settings = AppSettingsStore.shared.settings
            settings.betAmount = bet
            AppSettingsStore.shared.settings = settings
            betLabel.text = "\(bet)"
            onChange?(bet)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        betLabel.text = "\(bet)"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = UIColor.white.withAlphaComponent(0.16)
        layer.cornerRadius = 24

        [minusButton, plusButton].forEach {
            $0.setTitleColor(.white, for: .normal)
            $0.titleLabel?.font = .rounded(size: 24, weight: .black)
            $0.layer.cornerRadius = 16
            $0.addPressAnimation()
        }
        minusButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
        plusButton.backgroundColor = .brandGold
        minusButton.setTitle("-", for: .normal)
        plusButton.setTitle("+", for: .normal)
        betLabel.font = .rounded(size: 24, weight: .black)
        betLabel.textColor = .white
        betLabel.textAlignment = .center
        betLabel.adjustsFontSizeToFitWidth = true
        betLabel.minimumScaleFactor = 0.72

        let title = UILabel()
        title.text = "BET"
        title.font = .rounded(size: 15, weight: .black)
        title.textColor = .white

        addSubview(title)
        addSubview(minusButton)
        addSubview(betLabel)
        addSubview(plusButton)

        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
        minusButton.snp.makeConstraints { make in
            make.trailing.equalTo(betLabel.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
        }
        betLabel.snp.makeConstraints { make in
            make.trailing.equalTo(plusButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(64)
        }
        plusButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(36)
        }
        snp.makeConstraints { make in
            make.height.equalTo(48)
        }

        minusButton.addAction(UIAction { [weak self] _ in self?.bet -= 50 }, for: .touchUpInside)
        plusButton.addAction(UIAction { [weak self] _ in self?.bet += 50 }, for: .touchUpInside)
    }
}

final class JackpotCounterLabel: UILabel {
    private var displayLink: CADisplayLink?
    private var fromValue = 0
    private var toValue = 0
    private var startTime: CFTimeInterval = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .displayBig
        textColor = .brandGold
        textAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func roll(to value: Int) {
        fromValue = toValue == 0 ? value - 1200 : toValue
        toValue = value
        startTime = CACurrentMediaTime()
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func tick() {
        let progress = min(1, (CACurrentMediaTime() - startTime) / 0.8)
        let eased = 1 - pow(1 - progress, 3)
        let value = fromValue + Int(Double(toValue - fromValue) * eased)
        text = Formatters.integer.string(from: NSNumber(value: value))
        if progress >= 1 {
            displayLink?.invalidate()
            displayLink = nil
            UIView.animate(withDuration: 0.12, animations: {
                self.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }) { _ in
                UIView.animate(withDuration: 0.18) {
                    self.transform = .identity
                }
            }
        }
    }
}

final class BigWinOverlayView: UIView {
    private let card = GradientView(gradient: .jackpotGradient(), cornerRadius: Radius.large)
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        alpha = 0
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        label.font = .h1
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true

        addSubview(card)
        card.addSubview(label)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Spacing.xxl)
            make.height.equalTo(96)
        }
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Spacing.lg)
        }
    }

    func show(amount: Int, in parent: UIView) {
        label.text = "BIG WIN! +\(Formatters.coins(amount))"
        parent.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.62, initialSpringVelocity: 0.8) {
            self.alpha = 1
            self.transform = .identity
        }
        emitParticles()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
    }

    private func emitParticles() {
        for index in 0..<12 {
            let particle = CALayer()
            particle.backgroundColor = UIColor.brandGold.cgColor
            particle.cornerRadius = 4
            particle.frame = CGRect(x: bounds.midX, y: bounds.midY, width: 8, height: 8)
            layer.addSublayer(particle)

            let angle = CGFloat(index) / 12 * .pi * 2
            let distance: CGFloat = 130
            let end = CGPoint(x: bounds.midX + cos(angle) * distance, y: bounds.midY + sin(angle) * distance)

            let move = CABasicAnimation(keyPath: "position")
            move.fromValue = CGPoint(x: bounds.midX, y: bounds.midY)
            move.toValue = end
            move.duration = 1.2
            move.timingFunction = CAMediaTimingFunction(name: .easeOut)

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            fade.duration = 1.2

            let group = CAAnimationGroup()
            group.animations = [move, fade]
            group.duration = 1.2
            group.fillMode = .forwards
            group.isRemovedOnCompletion = false
            particle.add(group, forKey: "particle")
        }
    }
}
