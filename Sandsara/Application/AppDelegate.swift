//
//  AppDelegate.swift
//  Sandsara
//
//  Created by Tín Phan on 11/7/20.
//

import UIKit
import RxSwift
import RxBluetoothKit
import CoreBluetooth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let bag = DisposeBag()

    var connectedPeperial: Peripheral? {
        didSet {
            if connectedPeperial != nil {
                centralManager.observeConnect(for: connectedPeperial).subscribeNext {
                    print($0.state)
                }.disposed(by: bag)
            }
        }
    }

    // 1) - initialization of CentralManager
    private let centralManager: CentralManager = {
        let bluetoothCommunicationSerialQueue = DispatchQueue(label: "bluetoothCommunicationSerialQueue")
        let centralManagerOptions = [
            // The system uses this UID to identify a specific central manager.
            // As a result, the UID must remain the same for subsequent executions of
            // the app in order for the central manager to be successfully restored.
            CBCentralManagerOptionRestoreIdentifierKey: "com.ios.sandsara",
            // A Boolean value that specifies whether the system should display a warning dialog
            // to the user if Bluetooth is powered off when the central manager is instantiated.
            CBCentralManagerOptionShowPowerAlertKey: true
        ] as [String: AnyObject]

        return CentralManager(queue: bluetoothCommunicationSerialQueue, options: centralManagerOptions)
    }()


    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        DataLayer.shareInstance.config()
        AppApperance.setTheme()

        getConnected()
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
        let timerQueue = DispatchQueue(label: "com.ios.sandsara.timer")
        let scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
        centralManager.observeState()
            .startWith(centralManager.state)
            .filter {
                $0 == .poweredOn
            }
            .subscribeOn(MainScheduler.instance)
            .debounce(RxTimeInterval.milliseconds(400), scheduler: scheduler)
            .flatMap { [weak self] _ -> Observable<ScannedPeripheral> in
                guard let `self` = self else {
                    return Observable.empty()
                }
                return self.centralManager.scanForPeripherals(withServices: nil)
            }.subscribe(onNext: { [weak self] scannedPeripheral in
                guard let self = self else { return }
                if scannedPeripheral.peripheral.name == "Sandsara BLE" {
                    self.centralManager.establishConnection(scannedPeripheral.peripheral).subscribe(onNext: { [weak self] device in
                        guard let self = self else { return }
                        self.connectedPeperial = device
                        (self.window?.rootViewController?.tabBarController?.popupBar as? PlayerBarViewController)?.state = .connected
                        print("connected")
                    }, onError: { [weak self] error in
                        print(error.localizedDescription)
                    }).disposed(by: self.bag)
                }
            }, onError: { [weak self] error in
                print(error)
            }).disposed(by: bag)
    }

    func getConnected() {
        // TODO :get connected devices

        if centralManager.retrieveConnectedPeripherals(withServices: []).isEmpty {
            pairing()
        } else {
            if let item = centralManager.retrieveConnectedPeripherals(withServices: []).filter { $0.peripheral.name == "Sandsara BLE" }.first {
                self.connectedPeperial = item
            }
        }

        // TODO: connect to a connected , get characteristics

        // TODO: not found then run pair function

    }
}

