import UIKit

/// 修复：隐藏系统导航栏（.toolbar(.hidden)）后，二级页面右滑返回手势失效的问题。
/// SwiftUI 隐藏导航栏时会把 interactivePopGestureRecognizer 的代理重置，导致手势被禁用；
/// 这里重新挂上代理，并在栈里有上级页面时允许右滑返回（viewControllers.count > 1）。
extension UINavigationController: UIGestureRecognizerDelegate {
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
