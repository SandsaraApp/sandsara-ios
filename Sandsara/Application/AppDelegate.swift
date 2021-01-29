//
//  AppDelegate.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import UIKit
import RxSwift
import Bluejay
import Firebase

let bluejay = Bluejay()
@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var discoveredDevice: ScanDiscovery?

    let disposeBag = DisposeBag()

    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        DataLayer.shareInstance.config()
        AppApperance.setTheme()
        let backgroundRestoreConfig = BackgroundRestoreConfig(
            restoreIdentifier: "com.ios.sandsara",
            backgroundRestorer: self,
            listenRestorer: self,
            launchOptions: launchOptions)

        let backgroundRestoreMode = BackgroundRestoreMode.enable(backgroundRestoreConfig)

        let options = StartOptions(
            enableBluetoothAlert: true,
            backgroundRestore: backgroundRestoreMode)

        bluejay.registerDisconnectHandler(handler: self)
        bluejay.start(mode: .new(options))

        SandsaraDataServices().getColorPalettes(option: SandsaraDataServices().getServicesOption(for: .colorPalette)).subscribeNext { colors in
            print(colors)
        }.disposed(by: disposeBag)

        FirebaseApp.configure()
    DataLayer.init()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        // observe connection

        ReachabilityManager.shared.stopMonitoring()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        ReachabilityManager.shared.stopMonitoring()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ReachabilityManager.shared.startMonitoring()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ReachabilityManager.shared.stopMonitoring()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func initPlayerBar() {
        let player = PlayerViewController.shared
        player.modalPresentationStyle = .fullScreen
        player.popupContentView.popupCloseButtonStyle = .none

        if UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController == nil {
            let customBar = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: PlayerBarViewController.identifier) as! PlayerBarViewController
            customBar.state = bluejay.isConnected ? (DeviceServiceImpl.shared.status.value == .busy ? .busy : .connected ) : .noConnect
            UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController = customBar
        }
        UIApplication.topViewController()?.tabBarController?.popupBar.isHidden = false
        UIApplication.topViewController()?.tabBarController?.popupContentView.popupCloseButton.isHidden = true
        UIApplication.topViewController()?.tabBarController?.presentPopupBar(withContentViewController: player, openPopup: false, animated: false, completion: nil)


    }
}

extension AppDelegate: BackgroundRestorer {
    func didRestoreConnection(
        to peripheral: PeripheralIdentifier) -> BackgroundRestoreCompletion {
        // Opportunity to perform syncing related logic here.
        
        return .continue
    }

    func didFailToRestoreConnection(
        to peripheral: PeripheralIdentifier, error: Error) -> BackgroundRestoreCompletion {
        // Opportunity to perform cleanup or error handling logic here.
        DeviceServiceImpl.shared.cleanup()
        return .continue
    }
}

extension AppDelegate: ListenRestorer {
    func didReceiveUnhandledListen(
        from peripheral: PeripheralIdentifier,
        on characteristic: CharacteristicIdentifier,
        with value: Data?) -> ListenRestoreAction {
        // Re-install or defer installing a callback to a notifying characteristic.
        return .promiseRestoration
    }
}

extension AppDelegate: DisconnectHandler {
    func didDisconnect(from peripheral: PeripheralIdentifier, with error: Error?, willReconnect autoReconnect: Bool) -> AutoReconnectMode {
        DispatchQueue.main.async {
            (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .noConnect
        }
        DeviceServiceImpl.shared.cleanup()
        return .noChange
    }
}
