import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }

    static let brandPink = UIColor(hex: "#FF6B9D")
    static let brandPurple = UIColor(hex: "#A78BFA")
    static let brandGold = UIColor(hex: "#FCD34D")
    static let accentCyan = UIColor(hex: "#06B6D4")
    static let accentOrange = UIColor(hex: "#FB923C")
    static let bgPrimary = UIColor(hex: "#FFF5F7")
    static let bgLavender = UIColor(hex: "#F3E8FF")
    static let deepPurple = UIColor(hex: "#21194F")
    static let midPurple = UIColor(hex: "#442082")
    static let bgCard = UIColor.white
    static let bgDark = UIColor(hex: "#1A1B2E")
    static let success = UIColor(hex: "#10B981")
    static let locked = UIColor(hex: "#9CA3AF")
    static let warning = UIColor(hex: "#EF4444")
    static let textPrimary = UIColor(hex: "#18191C")
    static let textSecondary = UIColor(hex: "#6B7280")
}

enum PrototypeGradient {
    static func lightBackground() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hex: "#FCE0EA").cgColor,
            UIColor(hex: "#F8E4F4").cgColor,
            UIColor(hex: "#F1E8FF").cgColor
        ]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }

    static func gameBackground() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(hex: "#21194F").cgColor,
            UIColor(hex: "#321B6D").cgColor,
            UIColor(hex: "#55199A").cgColor
        ]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }

    static func pinkPurple() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(hex: "#F85B9A").cgColor, UIColor(hex: "#A77CF6").cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }

    static func goldPink() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(hex: "#FFC226").cgColor, UIColor(hex: "#FB5D9E").cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }

    static func cyan() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(hex: "#08B6C9").cgColor, UIColor(hex: "#63DCEC").cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }

    static func seven() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [UIColor(hex: "#FF416B").cgColor, UIColor(hex: "#FF8AAD").cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }
}

extension UIFont {
    static let displayHero = UIFont.rounded(size: 32, weight: .black)
    static let displayBig = UIFont.rounded(size: 28, weight: .bold)
    static let h1 = UIFont.rounded(size: 24, weight: .bold)
    static let h2 = UIFont.rounded(size: 20, weight: .semibold)
    static let h3 = UIFont.rounded(size: 17, weight: .semibold)
    static let body = UIFont.rounded(size: 15, weight: .regular)
    static let bodyBold = UIFont.rounded(size: 15, weight: .semibold)
    static let caption = UIFont.rounded(size: 13, weight: .regular)
    static let micro = UIFont.rounded(size: 11, weight: .medium)
    static let tabLabel = UIFont.rounded(size: 10, weight: .semibold)
    static let button = UIFont.rounded(size: 15, weight: .bold)

    static func rounded(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let system = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = system.fontDescriptor.withDesign(.rounded) else {
            return system
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

enum Radius {
    static let pill: CGFloat = 999
    static let large: CGFloat = 24
    static let medium: CGFloat = 16
    static let small: CGFloat = 12
    static let tiny: CGFloat = 8
}

extension CAGradientLayer {
    static func brandGradient() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.brandPink.cgColor, UIColor.brandPurple.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }

    static func goldGradient() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.brandGold.cgColor, UIColor(hex: "#FBBF24").cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        return layer
    }

    static func jackpotGradient() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.brandPink.cgColor, UIColor.brandPurple.cgColor, UIColor.brandGold.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }
}

final class GradientView: UIView {
    private let gradientLayer: CAGradientLayer

    init(gradient: CAGradientLayer, cornerRadius: CGFloat = 0) {
        self.gradientLayer = gradient
        super.init(frame: .zero)
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

extension UIView {
    func applySoftShadow() {
        layer.shadowColor = UIColor.black.withAlphaComponent(0.06).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
    }

    func applyCardShadow() {
        layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }

    func applyGlowShadow(color: UIColor) {
        layer.shadowColor = color.withAlphaComponent(0.4).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 20
        layer.shadowOffset = .zero
    }

    func addPressAnimation() {
        guard let control = self as? UIControl else { return }
        control.addAction(UIAction { [weak control] _ in
            UIView.animate(withDuration: 0.12, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                control?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }, for: .touchDown)
        control.addAction(UIAction { [weak control] _ in
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                control?.transform = .identity
            }
        }, for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
}
