import UIKit

final class StartupLoadingViewController: UIViewController {
    private let mark = GradientView(gradient: PrototypeGradient.pinkPurple(), cornerRadius: 64)

    override func loadView() {
        view = GradientView(gradient: PrototypeGradient.lightBackground())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        startBreathingAnimation()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .darkContent
    }

    private func configureView() {
        let markLabel = UILabel()
        markLabel.text = "V"
        markLabel.textColor = .white
        markLabel.font = .rounded(size: 56, weight: .black)
        markLabel.textAlignment = .center

        let titleLabel = UILabel()
        titleLabel.text = "Preparing your session"
        titleLabel.textColor = .deepPurple
        titleLabel.font = .displayBig
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Connecting securely..."
        subtitleLabel.textColor = .textSecondary
        subtitleLabel.font = .body
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        view.addSubview(mark)
        mark.addSubview(markLabel)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)

        mark.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-70)
            make.width.height.equalTo(128)
        }
        markLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mark.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(28)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(28)
        }
    }

    private func startBreathingAnimation() {
        mark.layer.removeAllAnimations()
        UIView.animate(
            withDuration: 1.8,
            delay: 0,
            options: [.autoreverse, .repeat, .curveEaseInOut, .allowUserInteraction]
        ) { [weak self] in
            self?.mark.alpha = 0.78
            self?.mark.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }
}
