import UIKit

final class RewardsViewController: BaseViewController {
    private let store = AppRewardsStore.shared
    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private let activeStack = UIStackView()
    private let rewardsStack = UIStackView()
    private weak var pointsLabel: UILabel?

    override func loadView() {
        view = PrototypeBackgroundView(style: .light)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setup()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshRewards),
            name: .didUpdateRewards,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshRewards()
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

        activeStack.axis = .vertical
        activeStack.spacing = 10
        rewardsStack.axis = .vertical
        rewardsStack.spacing = 12

        stack.addArrangedSubview(makeTopBar())
        stack.setCustomSpacing(24, after: stack.arrangedSubviews.last!)
        stack.addArrangedSubview(makePointsCard())
        stack.addArrangedSubview(makeSectionTitle("Active Perks"))
        stack.addArrangedSubview(activeStack)
        stack.addArrangedSubview(makeSectionTitle("Points Store"))
        stack.addArrangedSubview(rewardsStack)
        refreshRewards()
    }

    private func makeTopBar() -> UIView {
        let bar = UIView()
        let title = UILabel()
        title.text = "Rewards"
        title.textAlignment = .center
        title.font = .rounded(size: 26, weight: .black)
        title.textColor = .midPurple

        bar.addSubview(title)
        title.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(48)
        }
        bar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        return bar
    }

    private func makePointsCard() -> UIView {
        let card = GradientView(gradient: PrototypeGradient.pinkPurple(), cornerRadius: 24)
        card.applyCardShadow()

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = .brandGold
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "Reward Points"
        title.font = .rounded(size: 18, weight: .black)
        title.textColor = .white

        let subtitle = UILabel()
        subtitle.text = "Earn points from spins, then spend them on perks."
        subtitle.font = .rounded(size: 14, weight: .medium)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.84)
        subtitle.numberOfLines = 2

        let points = UILabel()
        points.textAlignment = .right
        points.font = .rounded(size: 30, weight: .black)
        points.textColor = .white
        points.adjustsFontSizeToFitWidth = true
        points.minimumScaleFactor = 0.74
        pointsLabel = points

        card.addSubview(icon)
        card.addSubview(title)
        card.addSubview(subtitle)
        card.addSubview(points)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(34)
        }
        title.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(18)
            make.trailing.lessThanOrEqualTo(points.snp.leading).offset(-12)
        }
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalTo(title.snp.bottom).offset(8)
        }
        points.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-18)
            make.centerY.equalTo(title)
            make.width.equalTo(120)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(128)
        }
        return card
    }

    private func makeSectionTitle(_ text: String) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.text = text
        label.font = .rounded(size: 20, weight: .black)
        label.textColor = .midPurple
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.centerY.equalToSuperview()
        }
        container.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        return container
    }

    @objc private func refreshRewards() {
        pointsLabel?.text = Formatters.points(store.points)
        activeStack.arrangedSubviews.forEach { view in
            activeStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        rewardsStack.arrangedSubviews.forEach { view in
            rewardsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let activeRewards = store.activeRewards
        if activeRewards.isEmpty {
            activeStack.addArrangedSubview(makeEmptyActiveView())
        } else {
            activeRewards.forEach { activeStack.addArrangedSubview(makeActiveRow($0)) }
        }

        MockData.rewardsCatalog.forEach { item in
            rewardsStack.addArrangedSubview(makeRewardCard(item))
        }
    }

    private func makeEmptyActiveView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.72)
        view.layer.cornerRadius = 18
        view.layer.cornerCurve = .continuous

        let label = UILabel()
        label.text = "No active perks yet"
        label.textAlignment = .center
        label.font = .rounded(size: 15, weight: .medium)
        label.textColor = .textSecondary

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        view.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
        return view
    }

    private func makeActiveRow(_ item: RewardItem) -> UIView {
        let row = UIView()
        row.backgroundColor = item.accentColor.withAlphaComponent(0.16)
        row.layer.cornerRadius = 18
        row.layer.cornerCurve = .continuous

        let icon = UIImageView(image: UIImage(systemName: item.iconName))
        icon.tintColor = item.accentColor
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = item.title
        label.font = .rounded(size: 15, weight: .black)
        label.textColor = .midPurple
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.78

        let state = PaddingLabel()
        state.text = item.kind == .bonusTicket ? "READY" : "NEXT SPIN"
        state.font = .rounded(size: 11, weight: .black)
        state.textColor = .white
        state.backgroundColor = item.accentColor
        state.layer.cornerRadius = 12
        state.layer.masksToBounds = true
        state.textAlignment = .center

        row.addSubview(icon)
        row.addSubview(label)
        row.addSubview(state)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(state.snp.leading).offset(-10)
        }
        state.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }
        row.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        return row
    }

    private func makeRewardCard(_ item: RewardItem) -> UIView {
        let card = UIControl()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.cornerCurve = .continuous
        card.applySoftShadow()
        card.addPressAnimation()
        card.addAction(UIAction { [weak self] _ in
            self?.redeem(item)
        }, for: .touchUpInside)

        let iconCircle = UIView()
        iconCircle.backgroundColor = item.accentColor
        iconCircle.layer.cornerRadius = 24
        iconCircle.layer.masksToBounds = true
        let icon = UIImageView(image: UIImage(systemName: item.iconName))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit

        let category = UILabel()
        category.text = item.categoryTitle
        category.font = .rounded(size: 10, weight: .black)
        category.textColor = item.accentColor

        let title = UILabel()
        title.text = item.title
        title.font = .rounded(size: 17, weight: .black)
        title.textColor = UIColor(hex: "#1F2937")
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.78

        let description = UILabel()
        description.text = item.description
        description.font = .rounded(size: 13, weight: .medium)
        description.textColor = .textSecondary
        description.numberOfLines = 2

        let status = makeStatusLabel(for: item)
        let cost = UILabel()
        cost.text = Formatters.points(item.cost)
        cost.font = .rounded(size: 15, weight: .black)
        cost.textColor = .midPurple
        cost.textAlignment = .right
        cost.adjustsFontSizeToFitWidth = true
        cost.minimumScaleFactor = 0.74

        let textStack = UIStackView(arrangedSubviews: [category, title, description])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.isUserInteractionEnabled = false

        iconCircle.addSubview(icon)
        card.addSubview(iconCircle)
        card.addSubview(textStack)
        card.addSubview(status)
        card.addSubview(cost)

        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(23)
        }
        iconCircle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(18)
            make.width.height.equalTo(48)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconCircle.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(17)
            make.trailing.equalToSuperview().offset(-16)
        }
        status.snp.makeConstraints { make in
            make.leading.equalTo(textStack)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(88)
        }
        cost.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(status)
            make.leading.greaterThanOrEqualTo(status.snp.trailing).offset(12)
            make.width.equalTo(100)
        }
        card.snp.makeConstraints { make in
            make.height.equalTo(136)
        }
        return card
    }

    private func makeStatusLabel(for item: RewardItem) -> UILabel {
        let label = PaddingLabel()
        label.font = .rounded(size: 12, weight: .black)
        label.textAlignment = .center
        label.layer.cornerRadius = 15
        label.layer.masksToBounds = true
        label.insets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

        if store.isRedeemed(item) {
            label.text = item.kind == .cosmetic ? "OWNED" : "ACTIVE"
            label.textColor = .white
            label.backgroundColor = item.accentColor
        } else if store.points >= item.cost {
            label.text = "REDEEM"
            label.textColor = .white
            label.backgroundColor = .midPurple
        } else {
            label.text = "NOT ENOUGH"
            label.textColor = .textSecondary
            label.backgroundColor = UIColor(hex: "#EEF0F4")
        }
        return label
    }

    private func redeem(_ item: RewardItem) {
        if store.isRedeemed(item) {
            showMessage(title: item.kind == .cosmetic ? "Already Owned" : "Already Active", message: "\(item.title) is ready to use.")
            return
        }
        guard store.redeem(item) else {
            showMessage(title: "Not Enough Points", message: "Play more spins and complete achievements to earn more points.")
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showMessage(title: "Redeemed", message: "\(item.title) has been added to your active rewards.")
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
