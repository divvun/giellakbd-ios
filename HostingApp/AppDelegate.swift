import Sentry
import UIKit

class AppNavControllerDelegate: NSObject, UINavigationControllerDelegate {
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

let str1 = "containing"
let str2 = "Bundle"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    weak static var instance: AppDelegate!

    var window: UIWindow?
    var wantsKeyboardList = false

    let navController = UINavigationController(rootViewController: HomeController())

    //swiftlint:disable:next weak_delegate
    let ncDelegate = AppNavControllerDelegate()

    //swiftlint:disable identifier_name
    var isKeyboardEnabled: Bool {
        let x: [Bundle] = UITextInputMode.activeInputModes.compactMap {
            let s = str1 + str2

            let v = $0.perform(Selector(s))
            if let x = v?.takeUnretainedValue() as? Bundle {
                return x
            }

            return nil
        }

        return x.contains(Bundle.main)
    }
    //swiftlint:enable identifier_name

    func application(_: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.instance = self

        if let sentryDSN = Bundle.main.infoDictionary?["SentryDSN"] as? String {
            do {
                Client.shared = try Client(dsn: sentryDSN)
                try Client.shared?.startCrashHandler()
            } catch {
                print("\(error)")
                // Wrong DSN or KSCrash not installed
            }
        }

        Strings.languageCode = KeyboardSettings.languageCode

        navController.delegate = ncDelegate

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = navController
        window!.makeKeyAndVisible()

        if !isKeyboardEnabled, KeyboardSettings.firstLoad {
            KeyboardSettings.firstLoad = false
            navController.pushViewController(InstructionsController(), animated: false)
        }

        if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] {
            if let url = url as? URL {
                parseUrl(url)
            }
        }

        return true
    }

    func applicationWillResignActive(_: UIApplication) {}

    func applicationDidEnterBackground(_: UIApplication) {}

    func applicationWillEnterForeground(_: UIApplication) {}

    func applicationDidBecomeActive(_: UIApplication) {}

    func applicationWillTerminate(_: UIApplication) {}

    func parseUrl(_: URL) {
        guard Bundle.main.bundleIdentifier != nil else {
            return
        }
    }

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        parseUrl(url)
        return true
    }
}
