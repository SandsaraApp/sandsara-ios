//
//  ConnectionGuideViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 28/12/2020.
//

import UIKit

let connectedd = Notification.Name(rawValue: "connectedSuccess")

class ConnectionGuideViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var connectionHeaderLabel: UILabel!
    @IBOutlet weak var connectionDescLabel: UILabel!
    @IBOutlet weak var connectNowBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(connectedSuccess), name: connectedd, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: connectedd, object: nil)
    }

    @objc func connectedSuccess() {
        self.dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: reloadTab, object: nil)
        })
    }

    private func setupUI() {
        connectionHeaderLabel.text = L10n.connectToSandsara
        connectionDescLabel.text = L10n.connectDesc
        connectNowBtn.setTitle(L10n.connectNow, for: .normal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Asset.close.image, style: .done, target: self, action: #selector(dismissVC))
    }

    private func bindings() {
        connectNowBtn
            .rx.tap.asDriver()
            .driveNext {
            self.goToScanDevices()
        }.disposed(by: disposeBag)
    }

    private func goToScanDevices() {
        let scanVC: ScanViewController = self.storyboard?.instantiateViewController(withIdentifier: ScanViewController.identifier) as! ScanViewController
        let navVC = UINavigationController(rootViewController: scanVC)
        self.present(navVC, animated: true, completion: nil)
    }

    @objc func dismissVC() {
        self.dismiss(animated: true)
    }
}
