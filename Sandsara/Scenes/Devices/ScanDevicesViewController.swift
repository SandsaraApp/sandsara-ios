//
//  ScanDevicesViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 20/11/2020.
//

import UIKit
import Bluejay

class ScanViewController: BaseViewController<NoInputParam>, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.identifier)
        }
    }

    @IBOutlet weak var backBtn: UIBarButtonItem!

    var sensors: [ScanDiscovery] = []
    var selectedSensor: PeripheralIdentifier?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Scan Devices"

    

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ScanViewController.appDidResume),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ScanViewController.appDidBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        backBtn.rx.tap.asDriver().driveNext {
            self.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
    }

    @objc func appDidResume() {
        scanSensors()
    }

    @objc func appDidBackground() {
        bluejay.stopScanning()
    }

    private func scanSensors() {
        bluejay.scan(
            allowDuplicates: true,
            serviceIdentifiers: nil,
            discovery: { [weak self] _, discoveries -> ScanAction in
                guard let weakSelf = self else {
                    return .stop
                }

                weakSelf.sensors = discoveries
                weakSelf.tableView.reloadData()

                return .continue
            },
            expired: { [weak self] lostDiscovery, discoveries -> ScanAction in
                guard let weakSelf = self else {
                    return .stop
                }



                weakSelf.sensors = discoveries
                weakSelf.tableView.reloadData()

                return .continue
            },
            stopped: { _, error in
                if let error = error {
                    debugPrint("Scan stopped with error: \(error.localizedDescription)")
                } else {
                    debugPrint("Scan stopped without error")
                }
            })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bluejay.register(connectionObserver: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bluejay.unregister(connectionObserver: self)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sensors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.identifier, for: indexPath)

        cell.textLabel?.text = sensors[indexPath.row].peripheralIdentifier.name
        cell.detailTextLabel?.text = String(sensors[indexPath.row].rssi)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedSensor = sensors[indexPath.row].peripheralIdentifier

        bluejay.connect(selectedSensor, timeout: .seconds(15)) { result in
            switch result {
            case .success:
                debugPrint("Connection attempt to: \(selectedSensor.name) is successful")
            case .failure(let error):
                let alertVC = UIAlertController(title: "Alert", message: "Failed to connect to: \(selectedSensor.name) with error: \(error.localizedDescription)", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Try again", style: .default, handler: { _ in
                }))
                UIApplication.topViewController()?.present(alertVC, animated: true, completion: nil)
            }
        }
    }
}

extension ScanViewController: ConnectionObserver {
    func bluetoothAvailable(_ available: Bool) {
        debugPrint("ScanViewController - Bluetooth available: \(available)")

        if available {
            scanSensors()
        } else if !available {
            sensors = []
            tableView.reloadData()
        }
    }

    func connected(to peripheral: PeripheralIdentifier) {
        debugPrint("ScanViewController - Connected to: \(peripheral.description)")


        bluejay.read(from: ledStripSpeed) { [weak self] (result: ReadResult<String>) in

            switch result {
            case .success(let location):
                debugPrint("Read from sensor location is successful: \(location)")
                let alertVC = UIAlertController(title: "Alert", message: "Connection attempt to: \(peripheral.name) is successful", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self?.dismiss(animated: true, completion: nil)
                    DispatchQueue.main.async {
                        (UIApplication.topViewController()?.tabBarController?.popupBar.customBarViewController as? PlayerBarViewController)?.state = .connected
                    }
                }))
                UIApplication.topViewController()?.present(alertVC, animated: true, completion: nil)

            case .failure(let error):
                let alertVC = UIAlertController(title: "Alert", message: "Failed to read sensor location with error: \(error.localizedDescription)", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    bluejay.cancelEverything()
                }))
                UIApplication.topViewController()?.present(alertVC, animated: true, completion: nil)
                debugPrint("Failed to read sensor location with error: \(error.localizedDescription)")
            }
        }
    }
}

