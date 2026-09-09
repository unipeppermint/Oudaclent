import UIKit

final class CurrencyCardView: UIView {
    private let backgroundView: GradientView
    private let iconLabel = UILabel()
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    init(gradient: CAGradientLayer = .brandGradient()) {
        self.backgroundView = GradientView(gradient: gradient, cornerRadius: Radius.medium)
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        [iconLabel, valueLabel, titleLabel].forEach {
            $0.textAlignment = .center
            $0.textColor = .white
        }
        iconLabel.font = .h3
        valueLabel.font = .rounded(size: 21, weight: .black)
        valueLabel.adjustsFontSizeToFitWidth = true
        titleLabel.font = .caption

        let stack = UIStackView(arrangedSubviews: [iconLabel, valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = Spacing.xxs
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Spacing.sm)
        }
    }

    func configure(icon: String, value: Int, label: String) {
        iconLabel.text = icon
        valueLabel.text = Formatters.integer.string(from: NSNumber(value: value))
        titleLabel.text = label
    }
}

final class AchievementCardView: UIView {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let stateLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)

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

        iconView.contentMode = .scaleAspectFit
        titleLabel.font = .bodyBold
        titleLabel.textColor = .textPrimary
        descLabel.font = .caption
        descLabel.textColor = .textSecondary
        stateLabel.font = .micro
        stateLabel.textAlignment = .right
        progressView.progressTintColor = .brandGold
        progressView.trackTintColor = UIColor.locked.withAlphaComponent(0.18)

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(descLabel)
        addSubview(stateLabel)
        addSubview(progressView)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.lg)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(34)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(Spacing.md)
            make.top.equalToSuperview().offset(Spacing.md)
            make.trailing.lessThanOrEqualTo(stateLabel.snp.leading).offset(-Spacing.sm)
        }
        stateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.lg)
            make.centerY.equalTo(titleLabel)
            make.width.equalTo(70)
        }
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-Spacing.lg)
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.xxs)
        }
        progressView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(descLabel)
            make.top.equalTo(descLabel.snp.bottom).offset(Spacing.sm)
            make.height.equalTo(6)
        }
    }

    func configure(ach: Achievement) {
        iconView.image = UIImage(systemName: ach.iconName)
        iconView.tintColor = ach.unlocked ? .brandGold : .locked
        titleLabel.text = ach.title
        descLabel.text = ach.description
        stateLabel.text = ach.unlocked ? "Unlocked" : "Locked"
        stateLabel.textColor = ach.unlocked ? .success : .locked
        progressView.progress = Float(ach.currentProgress) / Float(max(1, ach.totalProgress))
    }
}

final class SlotRowView: UIView {
    private let icon = SymbolBadgeView(symbol: .seven, size: 52)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let playButton = PrimaryButton(title: "PLAY")

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
        titleLabel.font = .bodyBold
        titleLabel.textColor = .textPrimary
        subtitleLabel.font = .caption
        subtitleLabel.textColor = .textSecondary

        addSubview(icon)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(playButton)

        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.md)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(52)
        }
        playButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.md)
            make.centerY.equalToSuperview()
            make.width.equalTo(76)
            make.height.equalTo(36)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(Spacing.md)
            make.trailing.lessThanOrEqualTo(playButton.snp.leading).offset(-Spacing.sm)
            make.top.equalToSuperview().offset(Spacing.lg)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(Spacing.xxs)
        }
    }

    func configure(game: SlotGame) {
        titleLabel.text = game.title
        subtitleLabel.text = game.subtitle
    }
}

final class SettingsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "SettingsTableViewCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let toggle = UISwitch()
    private let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))

    var onToggle: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .bgCard
        contentView.backgroundColor = .bgCard

        iconView.tintColor = .brandPink
        iconView.contentMode = .scaleAspectFit
        titleLabel.font = .body
        titleLabel.textColor = .textPrimary
        valueLabel.font = .caption
        valueLabel.textColor = .textSecondary
        arrow.tintColor = .locked

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(toggle)
        contentView.addSubview(arrow)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Spacing.lg)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(Spacing.md)
            make.centerY.equalToSuperview()
        }
        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.lg)
            make.centerY.equalToSuperview()
        }
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-Spacing.lg)
            make.centerY.equalToSuperview()
            make.width.equalTo(12)
            make.height.equalTo(18)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(arrow.snp.leading).offset(-Spacing.sm)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(Spacing.sm)
        }
        toggle.addAction(UIAction { [weak self] _ in
            self?.onToggle?(self?.toggle.isOn ?? false)
        }, for: .valueChanged)
    }

    func configure(icon: String, title: String, value: String? = nil, switchValue: Bool? = nil) {
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        valueLabel.text = value
        if let switchValue {
            toggle.isHidden = false
            arrow.isHidden = true
            valueLabel.isHidden = true
            toggle.isOn = switchValue
        } else {
            toggle.isHidden = true
            arrow.isHidden = false
            valueLabel.isHidden = value == nil
        }
    }
}
