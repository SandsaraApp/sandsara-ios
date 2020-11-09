//
//  AppDelegate.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import UIKit
import Alamofire

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setTabBarAppearance()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    private func setTabBarAppearance() {
        UITabBarItem.appearance()
            .setTitleTextAttributes(
                [NSAttributedString.Key.foregroundColor: UIColor.appColor(.selectedColor)], for: .selected)
        UITabBarItem.appearance()
            .setTitleTextAttributes(
                [NSAttributedString.Key.foregroundColor: UIColor.appColor(.unselectedColor)], for: .normal)
        UITabBar.appearance().tintColor = UIColor.appColor(.selectedColor)
        UITabBar.appearance().backgroundColor =  UIColor.appColor(.tabBar)
    }

    func checkConfig() {
        AF.request("http://api.musicplus.io/data/ios.tube.minimize.json") { urlRequest in
            urlRequest.timeoutInterval = 15.0
            urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }.responseDecodable(of: Config.self) { [weak self] response in
            guard let self = self else { return }
            switch response.result {
            case .success(let config):
                Preferences.PlaylistsDomain.topListId = config.data?.top?.id
                Preferences.PlaylistsDomain.featuredList = config.data?.features
                Preferences.PlaylistsDomain.categories = config.data?.categories
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
}

