import UIKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    private let floatingTabBar = FloatingTabBarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureTabs()
        configureAppearance()
        setupFloatingTabBar()
    }

    private func configureTabs() {
        let lobby = UINavigationController(rootViewController: LobbyViewController())
        lobby.tabBarItem = item(for: .lobby)

        let game = GameViewController(game: MockData.hotSlots[0])
        game.tabBarItem = item(for: .game)

        let rewards = UINavigationController(rootViewController: RewardsViewController())
        rewards.tabBarItem = item(for: .rewards)

        let profile = UINavigationController(rootViewController: ProfileViewController())
        profile.tabBarItem = item(for: .me)

        viewControllers = [lobby, game, rewards, profile]
    }

    private func configureAppearance() {
        tabBar.isHidden = true
    }

    private func setupFloatingTabBar() {
        view.addSubview(floatingTabBar)
        floatingTabBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.height.equalTo(68)
        }
        floatingTabBar.onSelect = { [weak self] index in
            self?.selectTab(index)
        }
        updateFloatingTabBar()
    }

    private func selectTab(_ index: Int) {
        selectedIndex = index
        updateFloatingTabBar()
        setNeedsStatusBarAppearanceUpdate()
    }

    private func updateFloatingTabBar() {
        floatingTabBar.update(selectedIndex: selectedIndex, dark: selectedIndex == 1)
    }

    func showLobby() {
        selectTab(0)
    }

    func showGame() {
        selectTab(1)
    }

    func showGame(_ game: SlotGame) {
        let gameController = GameViewController(game: game)
        gameController.tabBarItem = item(for: .game)
        viewControllers?[1] = gameController
        selectTab(1)
    }

    func showRewards() {
        selectTab(2)
    }

    func showSettings() {
        selectTab(3)
        guard let navigationController = viewControllers?[3] as? UINavigationController else { return }
        if navigationController.topViewController is SettingsViewController { return }
        navigationController.pushViewController(SettingsViewController(), animated: true)
    }

    private func item(for tab: AppTab) -> UITabBarItem {
        UITabBarItem(
            title: tab.rawValue,
            image: UIImage(systemName: tab.iconName),
            selectedImage: UIImage(systemName: tab.iconNameSelected)
        )
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateFloatingTabBar()
        setNeedsStatusBarAppearanceUpdate()
    }

    override var childForStatusBarStyle: UIViewController? {
        selectedViewController
    }
}
