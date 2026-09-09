import UIKit

final class SettingsViewController: BaseViewController {
    private let viewModel = SettingsViewModel()
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

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
        stack.addArrangedSubview(makeLogoutButton())
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let back = CircleButton(text: "<", size: 40, background: .white, tint: .midPurple)
        back.addAction(UIAction { [weak self] _ in
            (self?.tabBarController as? MainTabBarController)?.showLobby()
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
        rows.addArrangedSubview(makeNavigationRow(symbolName: "star.fill", title: "Bet Amount", value: "100 Coins", color: .brandGold))
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
        rows.addArrangedSubview(makeNavigationRow(symbolName: "questionmark", title: "Help Center", value: nil, color: .brandPink))
        rows.addArrangedSubview(makeNavigationRow(symbolName: "phone.fill", title: "Contact Us", value: nil, color: .accentCyan))
        rows.addArrangedSubview(makeNavigationRow(symbolName: "info.circle.fill", title: "About Us", value: nil, color: .brandGold))
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
        let row = UIView()
        let iconView = makeIcon(symbolName: symbolName, color: color)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 18, weight: .black)
        titleLabel.textColor = .midPurple
        let toggle = UISwitch()
        toggle.onTintColor = .brandPink
        toggle.isOn = value
        toggle.addAction(UIAction { [weak self, weak toggle] _ in
            self?.viewModel.set(toggle?.isOn ?? false, for: keyPath)
        }, for: .valueChanged)

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

    private func makeNavigationRow(symbolName: String, title: String, value: String?, color: UIColor) -> UIView {
        let row = UIView()
        let iconView = makeIcon(symbolName: symbolName, color: color, size: 36)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(size: 18, weight: .medium)
        titleLabel.textColor = UIColor(hex: "#1F2937")
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .rounded(size: 17, weight: .medium)
        valueLabel.textColor = UIColor(hex: "#9CA3AF")
        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = UIColor(hex: "#D1D5DB")
        arrow.contentMode = .scaleAspectFit

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

    private func makeLogoutButton() -> UIView {
        let button = UIButton(type: .system)
        button.setTitle("Log Out", for: .normal)
        button.setTitleColor(.warning, for: .normal)
        button.titleLabel?.font = .rounded(size: 18, weight: .black)
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.warning.withAlphaComponent(0.45).cgColor
        button.backgroundColor = UIColor.white.withAlphaComponent(0.38)
        button.addPressAnimation()
        button.snp.makeConstraints { make in
            make.height.equalTo(52)
        }
        return button
    }
}
