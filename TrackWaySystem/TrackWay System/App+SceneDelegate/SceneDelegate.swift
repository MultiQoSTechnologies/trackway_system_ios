//
//  SceneDelegate.swift
//  DeliveryApp
//
//  Created by MQF-6 on 06/02/24.
//

import UIKit
import NotificationCenter

let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        LocationHelper.shared.requestLocation()
        registerForRemoteNotification()
        AppConfig.fetchSettings()
        
        let user = try? UserDefaults.standard.get(objectType: UserModel.self, forKey: "User")
        
        if user == nil {
            initLoginView()
        } else {
            Constant.user = user!
            initMapView()
        }
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        sendLocalNotification(
            title: "This is sample title",
            body: "This is simple body",
            userInfo: [
                "isOnline": false,
                "content-available": 1,
                "type": NotificationType.appTermination.rawValue
            ])
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

//  MARK: - Initil Screen Helpers -
extension SceneDelegate {
    func initMapView() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapVC") as! MapVC
        let navVC = UINavigationController(rootViewController: vc)
        window?.rootViewController = navVC
        window?.makeKeyAndVisible()
    }
    
    func initLoginView() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        let navVC = UINavigationController(rootViewController: vc)
        window?.rootViewController = navVC
        window?.makeKeyAndVisible()
    }
}



