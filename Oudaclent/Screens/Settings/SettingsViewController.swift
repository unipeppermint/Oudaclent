import UIKit

final class SettingsViewController: BaseViewController {
    private let viewModel = SettingsViewModel()
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private weak var betValueLabel: UILabel?

    override func loadView() {
        view = PrototypeBackgroundView(style: .light)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        betValueLabel?.text = "\(viewModel.settings.betAmount) Coins"
    }

    private func setup() {
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView) { make in
            make.edges.equalToSuperview()
        }
        scrollView.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 14
        stack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(58)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-126)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        stack.addArrangedSubview(makeTopBar())
        stack.setCustomSpacing(28, after: stack.arrangedSubviews.last!)
        stack.addArrangedSubview(makeGeneralCard())
        stack.addArrangedSubview(makeValueCard())
        stack.addArrangedSubview(makeSupportCard())
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let back = CircleButton(text: "<", size: 40, background: .white, tint: .midPurple)
        back.addAction(UIAction { [weak self] _ in
            if let navigationController = self?.navigationController, navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                (self?.tabBarController as? MainTabBarController)?.showLobby()
            }
        }, for: .touchUpInside)
        let title = UILabel()
        title.text = "Settings"
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
        }
        bar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return bar
    }

    private func makeGeneralCard() -> UIView {
        let card = makeWhiteCard()
        let header = UILabel()
        header.text = "GENERAL"
        header.font = .rounded(size: 16, weight: .black)
        header.textColor = .brandPurple

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 12
        rows.addArrangedSubview(makeToggleRow(symbolName: "music.note", title: "Sound", value: viewModel.settings.soundEnabled, keyPath: \.soundEnabled, color: .brandPurple))
        rows.addArrangedSubview(makeToggleRow(symbolName: "iphone.radiowaves.left.and.right", title: "Vibration", value: viewModel.settings.vibrationEnabled, keyPath: \.vibrationEnabled, color: .brandPink))
        rows.addArrangedSubview(makeToggleRow(symbolName: "bell.fill", title: "Notifications", value: viewModel.settings.notificationsEnabled, keyPath: \.notificationsEnabled, color: .brandGold))

        card.addSubview(header)
        card.addSubview(rows)
        header.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(14)
        }
        rows.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().offset(-14)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(178)
        }
        return card
    }

    private func makeValueCard() -> UIView {
        let card = makeWhiteCard()
        let rows = UIStackView()
        rows.axis = .vertical
        let betText = "\(viewModel.settings.betAmount) Coins"
        rows.addArrangedSubview(makeNavigationRow(symbolName: "star.fill", title: "Bet Amount", value: betText, color: .brandGold) { [weak self] in
            self?.showBetAmountPage()
        } valueLabelHandler: { [weak self] label in
            self?.betValueLabel = label
        })
        card.addSubview(rows)
        rows.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16))
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(72)
        }
        return card
    }

    private func makeSupportCard() -> UIView {
        let card = makeWhiteCard()
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 18
        rows.addArrangedSubview(makeNavigationRow(symbolName: "questionmark", title: "Help Center", value: nil, color: .brandPink) { [weak self] in
            self?.showHelpCenterPage()
        })
        rows.addArrangedSubview(makeNavigationRow(symbolName: "phone.fill", title: "Contact Us", value: nil, color: .accentCyan) { [weak self] in
            self?.showContactUs()
        })
        rows.addArrangedSubview(makeNavigationRow(symbolName: "info.circle.fill", title: "About Us", value: nil, color: .brandGold) { [weak self] in
            self?.showAbout()
        })
        card.addSubview(rows)
        rows.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16))
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(180)
        }
        return card
    }

    private func makeWhiteCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.applySoftShadow()
        return card
    }

    private func makeIcon(symbolName: String, color: UIColor, size: CGFloat = 28) -> UIView {
        let container = UIView()
        container.backgroundColor = color
        container.layer.cornerRadius = size / 2
        container.layer.masksToBounds = true
        let icon = UIImageView(image: UIImage(systemName: symbolName))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit

        container.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(size * 0.52)
        }
        container.snp.makeConstraints { make in
            make.width.height.equalTo(size)
        }
        return container
    }

    private func makeToggleRow(symbolName: String, title: String, value: Bool, keyPath: WritableKeyPath<AppSettings, Bool>, color: UIColor) -> UIView {
        let row = UIControl()
        let iconView = makeIcon(symbolName: symbolName, color: color)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 18, weight: .black)
        titleLabel.textColor = .midPurple
        let toggle = UISwitch()
        toggle.onTintColor = .brandPink
        toggle.isOn = value
        toggle.addAction(UIAction { [weak self, weak toggle] _ in
            guard let toggle else { return }
            self?.updateToggle(toggle, keyPath: keyPath, value: toggle.isOn)
        }, for: .valueChanged)
        row.addAction(UIAction { [weak self, weak toggle] _ in
            guard let toggle else { return }
            toggle.setOn(!toggle.isOn, animated: true)
            self?.updateToggle(toggle, keyPath: keyPath, value: toggle.isOn)
        }, for: .touchUpInside)
        row.addPressAnimation()

        row.addSubview(iconView)
        row.addSubview(titleLabel)
        row.addSubview(toggle)
        iconView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(toggle.snp.leading).offset(-12)
        }
        toggle.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
        }
        row.snp.makeConstraints { make in
            make.height.equalTo(32)
        }
        return row
    }

    private func makeNavigationRow(
        symbolName: String,
        title: String,
        value: String?,
        color: UIColor,
        action: (() -> Void)? = nil,
        valueLabelHandler: ((UILabel) -> Void)? = nil
    ) -> UIView {
        let row = UIControl()
        let iconView = makeIcon(symbolName: symbolName, color: color, size: 36)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 18, weight: .medium)
        titleLabel.textColor = UIColor(hex: "#1F2937")
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .rounded(size: 17, weight: .medium)
        valueLabel.textColor = UIColor(hex: "#9CA3AF")
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.78
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(hex: "#D1D5DB")
        arrow.contentMode = .scaleAspectFit
        arrow.isUserInteractionEnabled = false
        valueLabelHandler?(valueLabel)
        if let action {
            row.addAction(UIAction { _ in action() }, for: .touchUpInside)
            row.addPressAnimation()
        }

        row.addSubview(iconView)
        row.addSubview(titleLabel)
        row.addSubview(valueLabel)
        row.addSubview(arrow)
        iconView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(9)
            make.height.equalTo(16)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrow.snp.leading).offset(-14)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(10)
        }
        row.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        return row
    }

    private func updateToggle(_ toggle: UISwitch, keyPath: WritableKeyPath<AppSettings, Bool>, value: Bool) {
        viewModel.set(value, for: keyPath)
        if keyPath == \AppSettings.vibrationEnabled, value {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func showBetAmountPage() {
        let defaultAmount = 100
        viewModel.setBetAmount(defaultAmount)
        betValueLabel?.text = "\(defaultAmount) Coins"
        let controller = BetAmountViewController(currentAmount: defaultAmount) { [weak self] amount in
            self?.viewModel.setBetAmount(amount)
            self?.betValueLabel?.text = "\(amount) Coins"
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func showHelpCenterPage() {
        navigationController?.pushViewController(HelpCenterViewController(), animated: true)
    }

    private func showContactUs() {
        let email = "support@luckyslots.example"
        let alert = UIAlertController(title: "Contact Us", message: email, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy Email", style: .default) { _ in
            UIPasteboard.general.string = email
        })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func showAbout() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        showMessage(title: "About Us", message: "Lucky Slots\nVersion \(version)\nA casual slot prototype built for fast play and rewards.")
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private final class BetAmountViewController: BaseViewController {
    private var selectedAmount: Int
    private let onSelect: (Int) -> Void
    private let options = [50, 100, 150, 200, 300, 500]
    private let stack = UIStackView()
    private weak var summaryValueLabel: UILabel?
    private var checkmarks: [Int: UIImageView] = [:]

    init(currentAmount: Int, onSelect: @escaping (Int) -> Void) {
        self.selectedAmount = currentAmount
        self.onSelect = onSelect
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
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView) { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 14
        stack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(58)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-126)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        stack.addArrangedSubview(makeTopBar(title: "Bet Amount"))
        stack.setCustomSpacing(28, after: stack.arrangedSubviews.last!)
        stack.addArrangedSubview(makeSummaryCard())
        stack.addArrangedSubview(makeOptionsCard())
    }

    private func makeTopBar(title: String) -> UIView {
        let bar = UIView()
        let back = CircleButton(text: "<", size: 40, background: .white, tint: .midPurple)
        back.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.font = .rounded(size: 24, weight: .black)
        label.textColor = .midPurple
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.78

        bar.addSubview(back)
        bar.addSubview(label)
        back.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualTo(back.snp.trailing).offset(12)
        }
        bar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return bar
    }

    private func makeSummaryCard() -> UIView {
        let card = makeWhiteCard()
        let icon = makeIcon(symbolName: "star.fill", color: .brandGold, size: 48)
        let title = UILabel()
        title.text = "Default Bet"
        title.font = .rounded(size: 18, weight: .black)
        title.textColor = .midPurple
        let value = UILabel()
        value.text = "\(selectedAmount) Coins"
        value.font = .rounded(size: 28, weight: .black)
        value.textColor = UIColor(hex: "#1F2937")
        summaryValueLabel = value

        card.addSubview(icon)
        card.addSubview(title)
        card.addSubview(value)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-18)
        }
        value.snp.makeConstraints { make in
            make.leading.trailing.equalTo(title)
            make.top.equalTo(title.snp.bottom).offset(4)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(112)
        }
        return card
    }

    private func makeOptionsCard() -> UIView {
        let card = makeWhiteCard()
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 12
        options.forEach { amount in
            rows.addArrangedSubview(makeAmountRow(amount))
        }

        card.addSubview(rows)
        rows.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16))
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(444)
        }
        return card
    }

    private func makeAmountRow(_ amount: Int) -> UIView {
        let row = UIControl()
        row.backgroundColor = amount == selectedAmount ? UIColor.brandGold.withAlphaComponent(0.18) : UIColor(hex: "#F9FAFB")
        row.layer.cornerRadius = 16
        row.layer.cornerCurve = .continuous

        let title = UILabel()
        title.text = "\(amount) Coins"
        title.font = .rounded(size: 18, weight: .black)
        title.textColor = .midPurple

        let note = UILabel()
        note.text = amount <= 100 ? "Easy rounds" : amount >= 300 ? "High reward pace" : "Balanced play"
        note.font = .caption
        note.textColor = .textSecondary
        note.setContentCompressionResistancePriority(.required, for: .vertical)

        let textStack = UIStackView(arrangedSubviews: [title, note])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.isUserInteractionEnabled = false

        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = .brandPink
        check.contentMode = .scaleAspectFit
        check.isHidden = amount != selectedAmount
        checkmarks[amount] = check

        row.addSubview(textStack)
        row.addSubview(check)
        textStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(check.snp.leading).offset(-12)
        }
        check.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }
        row.snp.makeConstraints { make in
            make.height.equalTo(58)
        }
        row.addAction(UIAction { [weak self] _ in
            self?.selectAmount(amount)
        }, for: .touchUpInside)
        row.addPressAnimation()
        return row
    }

    private func selectAmount(_ amount: Int) {
        selectedAmount = amount
        onSelect(amount)
        summaryValueLabel?.text = "\(amount) Coins"
        checkmarks.forEach { key, checkmark in
            checkmark.isHidden = key != amount
            checkmark.superview?.backgroundColor = key == amount ? UIColor.brandGold.withAlphaComponent(0.18) : UIColor(hex: "#F9FAFB")
        }
    }

    private func makeWhiteCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.applySoftShadow()
        return card
    }

    private func makeIcon(symbolName: String, color: UIColor, size: CGFloat) -> UIView {
        let container = UIView()
        container.backgroundColor = color
        container.layer.cornerRadius = size / 2
        container.layer.masksToBounds = true
        let icon = UIImageView(image: UIImage(systemName: symbolName))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        container.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(size * 0.5)
        }
        container.snp.makeConstraints { make in
            make.width.height.equalTo(size)
        }
        return container
    }
}

private final class HelpCenterViewController: BaseViewController {
    private let items: [(String, String, String, UIColor)] = [
        ("gamecontroller.fill", "Start a Spin", "Tap GO on the game screen. Your selected bet is spent before each spin, and wins are added back to your coin balance.", .brandPink),
        ("slider.horizontal.3", "Adjust Bet", "Open Bet Amount from Settings or use the plus and minus buttons in the game screen to change your default wager.", .brandGold),
        ("list.bullet.rectangle", "Read Pay Tables", "Each slot feature page shows symbol combinations and multipliers so you can compare rewards before playing.", .accentCyan),
        ("gift.fill", "Collect Bonuses", "Daily check-in, free spins, multipliers, and pick bonuses are prototype reward flows shown across the app.", .brandPurple)
    ]

    override func loadView() {
        view = PrototypeBackgroundView(style: .light)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setup()
    }

    private func setup() {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView) { make in
            make.edges.equalToSuperview()
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(58)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(18)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-126)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-36)
        }

        stack.addArrangedSubview(makeTopBar())
        stack.setCustomSpacing(28, after: stack.arrangedSubviews.last!)
        items.forEach { item in
            stack.addArrangedSubview(makeHelpCard(iconName: item.0, title: item.1, body: item.2, color: item.3))
        }
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let back = CircleButton(text: "<", size: 40, background: .white, tint: .midPurple)
        back.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)

        let title = UILabel()
        title.text = "Help Center"
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
        }
        bar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return bar
    }

    private func makeHelpCard(iconName: String, title: String, body: String, color: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.applySoftShadow()

        let icon = UIView()
        icon.backgroundColor = color
        icon.layer.cornerRadius = 22
        icon.layer.masksToBounds = true
        let image = UIImageView(image: UIImage(systemName: iconName))
        image.tintColor = .white
        image.contentMode = .scaleAspectFit
        icon.addSubview(image)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 18, weight: .black)
        titleLabel.textColor = .midPurple

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = .rounded(size: 14, weight: .regular)
        bodyLabel.textColor = .textSecondary
        bodyLabel.numberOfLines = 0
        bodyLabel.lineBreakMode = .byWordWrapping

        card.addSubview(icon)
        card.addSubview(titleLabel)
        card.addSubview(bodyLabel)
        icon.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }
        image.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-16)
        }
        bodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
            make.bottom.lessThanOrEqualToSuperview().offset(-18)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(136)
        }
        return card
    }
}
