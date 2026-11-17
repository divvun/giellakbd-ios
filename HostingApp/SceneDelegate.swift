import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo _: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = AppDelegate.instance.navController
        window.makeKeyAndVisible()
        self.window = window

        AppDelegate.instance.showInstructionsOnFirstLaunchIfNeeded()

        for context in connectionOptions.urlContexts {
            AppDelegate.instance.parseUrl(context.url)
        }
    }

    func sceneWillEnterForeground(_: UIScene) {
        // I'd gladly use .NSExtensionHostWillEnterForeground but it doesn't work
        NotificationCenter.default.post(Notification(name: .HostingAppWillEnterForeground))
    }

    func scene(_: UIScene, openURLContexts urlContexts: Set<UIOpenURLContext>) {
        for context in urlContexts {
            AppDelegate.instance.parseUrl(context.url)
        }
    }
}
