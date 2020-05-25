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

    var window: UIWindow?
    var wantsKeyboardList = false

    let navController = UINavigationController(rootViewController: HomeController())

    //swiftlint:disable:next weak_delegate
    let ncDelegate = AppNavControllerDelegate()

    private let pahkat = PahkatWrapper()
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

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = navController
        window!.makeKeyAndVisible()

        let oneDay: Double = 60 * 60 * 24
        UIApplication.shared.setMinimumBackgroundFetchInterval(oneDay)

        if !isKeyboardEnabled, KeyboardSettings.firstLoad {
            KeyboardSettings.firstLoad = false
            navController.pushViewController(InstructionsController(), animated: false)
        }

        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] {
            if let url = url as? URL {
                parseUrl(url)
            }
        }

        installSpellersIfNeeded()

        return true
    }

    func installSpellersIfNeeded() {
        guard let pahkat = pahkat,
            pahkat.needsInstall,
            isInstalling == false else {
            return
        }
        isInstalling = true

        // TODO: this alert is made of jank, consider doing something nicer
        let currentViewController = navController.visibleViewController
        let alert = UIAlertController(title: "Installing Spellers", // TODO: localize
                                      message: " \n", // gives us space for the spinner
                                      preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(frame: alert.view.bounds)
        alert.view.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor).enable()
        spinner.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor, constant: 20).enable()
        spinner.isUserInteractionEnabled = false
        spinner.startAnimating()

        currentViewController?.present(alert, animated: true, completion: nil)

        pahkat.installSpellersForNewlyEnabledKeyboards(completion: { error in
            alert.dismiss(animated: true, completion: {
                self.isInstalling = false
            })
        })
    }

    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // TODO: check for actual updates and install those instead
        completionHandler(.newData)
    }

    func applicationWillEnterForeground(_: UIApplication) {
        // I'd gladly use .NSExtensionHostWillEnterForeground but it doesn't work
        NotificationCenter.default.post(Notification(name: .HostingAppWillEnterForeground))
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        installSpellersIfNeeded()
    }

    func parseUrl(_: URL) {
        guard Bundle.main.bundleIdentifier != nil else {
            return
        }
    }

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        parseUrl(url)
        return true
    }

    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        pahkat?.setBackgroundURLSessionCompletion(completionHandler)
    }
}
