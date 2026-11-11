import Sentry
import UIKit
import PahkatClient

final class AppNavControllerDelegate: NSObject, UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated _: Bool) {
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        navigationController.setNavigationBarHidden(viewController is HideNavBar, animated: true)
    }

    func navigationController(_: UINavigationController,
                              animationControllerFor _: UINavigationController.Operation,
                              from _: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        toVC.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        return nil
    }
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    weak static var instance: AppDelegate!

    var wantsKeyboardList = false

    let navController = UINavigationController(rootViewController: HomeController())

    //swiftlint:disable:next weak_delegate
    let ncDelegate = AppNavControllerDelegate()

    let pahkat = PahkatWrapper()
    private var isInstalling = false

    var isKeyboardEnabled: Bool {
        return !Bundle.enabledKeyboardBundles.isEmpty
    }

    func application(_: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.instance = self
        Pahkat.enableLogging()

        Strings.languageCode = KeyboardSettings.languageCode

        navController.delegate = ncDelegate

        // Migrate the databases
        UserDictionary.migrate()

        // The window, the first-launch instructions push and launch URLs are handled by
        // SceneDelegate once the window scene connects.

        let oneDay: Double = 60 * 60 * 24
        UIApplication.shared.setMinimumBackgroundFetchInterval(oneDay)

        return true
    }

    /// Pushes the setup instructions the first time the app runs without the keyboard enabled.
    /// Called by SceneDelegate after the window is on screen, matching the pre-scene launch order.
    func showInstructionsOnFirstLaunchIfNeeded() {
        if !isKeyboardEnabled, KeyboardSettings.firstLoad {
            KeyboardSettings.firstLoad = false
            navController.pushViewController(InstructionsController(), animated: false)
        }
    }

    func parseUrl(_: URL) {
        guard Bundle.main.bundleIdentifier != nil else {
            return
        }
    }
}
