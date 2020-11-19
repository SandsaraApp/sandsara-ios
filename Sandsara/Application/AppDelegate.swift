//
//  AppDelegate.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import UIKit
import RxSwift
import Bluejay
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

let bluejay = Bluejay()

let ledStripService = ServiceIdentifier(uuid: "fd31a2be-22e7-11eb-adc1-0242ac120002")

let ledStripSpeed = CharacteristicIdentifier(uuid: "1a9a7b7e-2305-11eb-adc1-0242ac120002", service: ledStripService)

let selectPattle = CharacteristicIdentifier(uuid: "1a9a813c-2305-11eb-adc1-0242ac120002", service: ledStripService)

let ledStripCycleEnable = CharacteristicIdentifier(uuid: "1a9a7dea-2305-11eb-adc1-0242ac120002", service: ledStripService)

let ledStripDirection = CharacteristicIdentifier(uuid: "1a9a8042-2305-11eb-adc1-0242ac120002", service: ledStripService)

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var discoveredDevice: ScanDiscovery?

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

        AppCenter.start(withAppSecret: "c037a178-abc5-4a57-bb58-cc53c3fb43d6", services:[
            Analytics.self,
            Crashes.self
        ])
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

    func pairing() {
        // TODO: store uuid in this function
        guard let device = discoveredDevice else { return }
        bluejay.connect(device.peripheralIdentifier, timeout: .seconds(15)) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .connected
                }
                debugPrint("Connection attempt to: \(device.peripheralIdentifier.description) is successful")
            case .failure(let error):
                debugPrint("Failed to connect with error: \(error.localizedDescription)")
            }
        }
    }

    func getConnected() {
        bluejay.scan(
            duration: 15,
            allowDuplicates: false,
            serviceIdentifiers: nil ,
            discovery: { [weak self] (discovery, discoveries) -> ScanAction in
                guard let weakSelf = self else {
                    return .stop
                }
                if discovery.peripheralIdentifier.name == "Sandsara BLE" {
                    weakSelf.discoveredDevice = discovery
                    DispatchQueue.main.async {
                        (weakSelf.window?.rootViewController?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .connected
                    }
                    self?.pairing()
                    Preferences.AppDomain.connectedSandasa = [discovery.peripheralIdentifier.uuid.uuidString]
                }
                return .continue
            },
            expired: { [weak self] (lostDiscovery, discoveries) -> ScanAction in
                guard let weakSelf = self else {
                    return .stop
                }
                debugPrint("Lost discovery: \(lostDiscovery)")
                return .continue
            }) { (discoveries, error) in
            if let error = error {
                debugPrint("Scan stopped with error: \(error.localizedDescription)")
            }
            else {
                debugPrint("Scan stopped without error.")
            }
        }
    }

    func initPlayerBar() {
        let player = PlayerViewController.shared
        player.modalPresentationStyle = .fullScreen
        player.selecledIndex.accept(0)
        player.tracks = []
        player.popupContentView.popupCloseButtonStyle = .none

        if UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController == nil {
            let customBar = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: PlayerBarViewController.identifier) as! PlayerBarViewController
            customBar.state = bluejay.isConnected ? .connected : .noConnect
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
        DispatchQueue.main.async {
            (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .connected
        }
        return .continue
    }

    func didFailToRestoreConnection(
        to peripheral: PeripheralIdentifier, error: Error) -> BackgroundRestoreCompletion {
        // Opportunity to perform cleanup or error handling logic here.
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
        return .change(shouldAutoReconnect: false)
    }
}


extension UIApplication {

    class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }

        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }

        return base
    }

}
