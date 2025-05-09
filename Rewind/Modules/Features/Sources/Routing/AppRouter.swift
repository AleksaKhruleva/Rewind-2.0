import SwiftUI
import UIKit

@MainActor
@Observable
public final class AppRouter {
    private unowned let coordinator: NavigationCoordinator?
    
    init(coordinator: NavigationCoordinator? = nil) {
        self.coordinator = coordinator
    }
    
    func navigate(to route: Route) {
        coordinator?.show(route: route)
    }
    
    func pop(by count: Int) {
        coordinator?.pop(by: count, animated: true)
    }
    
    func back() {
        coordinator?.pop()
    }
    
    public enum Route: Hashable {
        case welcome
        
        case email(AuthFlow)
        case code(email: String, registrationID: String)
        case password(AuthFlow, registrationID: String?)
        case name(email: String, password: String, registrationID: String)
        
        case rewind
        case map
        
        case account
        case gallery
        case quote
        case mediaDetails(UIImage)
    }
}

@MainActor
public final class NavigationCoordinator: NSObject, ObservableObject, UINavigationControllerDelegate {
    public weak var navigationController: UINavigationController?
    private(set) var appRouter: AppRouter!
    
    private var isCustomPushActive = false
    
    public override init() {
        super.init()
        self.appRouter = AppRouter(coordinator: self)
    }
    
    public func start(with navigationController: UINavigationController, initialRoute: AppRouter.Route) {
        self.navigationController = navigationController
        navigationController.delegate = self
        show(route: initialRoute, animated: false)
    }
    
    func show(route: AppRouter.Route, animated: Bool = true) {
        if route == .gallery {
            isCustomPushActive = true
        }
        
        let vc = viewController(for: route)
        navigationController?.pushViewController(vc, animated: animated)
    }
    
    func pop() {
        navigationController?.popViewController(animated: true)
    }
    
    func pop(by count: Int, animated: Bool = true) {
        guard let navigationController,
              count > 0,
              navigationController.viewControllers.count > count else {
            return
        }
        
        let targetIndex = navigationController.viewControllers.count - count - 1
        let targetVC = navigationController.viewControllers[targetIndex]
        navigationController.popToViewController(targetVC, animated: animated)
    }
    
    private func viewController(for route: AppRouter.Route) -> UIViewController {
        switch route {
        case .account:
            return UIHostingController(rootView: AccountView(router: AccountRouter(appRouter: appRouter)))
        case .gallery:
            return UIHostingController(rootView: GalleryView(router: GalleryRouter(appRouter: appRouter)))
        case .quote:
            return UIHostingController(rootView: QuoteCreationView())
        case let .mediaDetails(image):
            return UIHostingController(rootView: MediaDetailsView(image: image))
        case let .email(flow):
            return UIHostingController(rootView: EmailInputView(flow: flow, router: AuthenticationRouter(appRouter: appRouter)))
        case let .code(email, registrationID):
            return UIHostingController(rootView: CodeInputView(router: AuthenticationRouter(appRouter: appRouter), email: email, registrationID: registrationID))
        case let .password(flow, registrationID):
            return UIHostingController(rootView: PasswordInputView(flow: flow, router: AuthenticationRouter(appRouter: appRouter), registrationID: registrationID))
        case let .name(email, password, registrationID):
            return UIHostingController(rootView: NameInputView(router: AuthenticationRouter(appRouter: appRouter), email: email, password: password, registrationID: registrationID))
        case .rewind:
            let controller = UIHostingController(rootView: RewindView(router: RewindRouter(appRouter: appRouter)))
            controller.safeAreaRegions = []
            return controller
        case .welcome:
            return UIHostingController(rootView: WelcomeView(router: AuthenticationRouter(appRouter: appRouter)))
        case .map:
            return UIHostingController(rootView: RewindsMap())
        }
    }
    
    // MARK: - UINavigationControllerDelegate
    
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard isCustomPushActive, operation == .push else {
            return nil
        }
        isCustomPushActive = false
        return SlideFromBottomPushAnimator()
    }
}


final class SlideFromBottomPushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.35
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let container = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
        toView.frame = finalFrame.offsetBy(dx: 0, dy: container.bounds.height)
        container.addSubview(toView)
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            toView.frame = finalFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
