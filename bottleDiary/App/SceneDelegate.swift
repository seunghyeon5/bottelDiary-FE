import UIKit
import SwiftUI

// UIKit 생명주기에서 SwiftUI 루트 화면을 연결하는 델리게이트
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    // 앱 시작 시 RootView를 윈도우의 시작 화면으로 설정
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: RootView())
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
