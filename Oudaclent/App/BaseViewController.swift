import UIKit

class BaseViewController: UIViewController {
    override func loadView() {
        view = UIView()
        view.backgroundColor = .bgPrimary
    }

    func addSubview(_ subview: UIView, _ make: (ConstraintMaker) -> Void) {
        view.addSubview(subview)
        subview.snp.makeConstraints(make)
    }
}
