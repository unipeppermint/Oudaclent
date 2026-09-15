import UIKit

final class StartupLoadingViewController: UIViewController {
    override func loadView() {
        let artwork = UIImageView(image: UIImage(named: "LaunchArtwork"))
        artwork.contentMode = .scaleAspectFill
        artwork.clipsToBounds = true
        artwork.backgroundColor = UIColor(red: 0.10, green: 0.02, blue: 0.35, alpha: 1)
        view = artwork
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
