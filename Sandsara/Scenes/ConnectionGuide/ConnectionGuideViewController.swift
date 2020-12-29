//
//  ConnectionGuideViewController.swift
//  Sandsara
//
//  Created by Tín Phan on 28/12/2020.
//

import UIKit

class ConnectionGuideViewController: BaseViewController<NoInputParam> {

    @IBOutlet weak var connectionHeaderLabel: UILabel!
    @IBOutlet weak var connectionDescLabel: UILabel!
    @IBOutlet weak var connectNowBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindings()
    }

    private func setupUI() {
        connectionHeaderLabel.text = L10n.connectToSandsara
        connectionDescLabel.text = L10n.connectDesc
        connectNowBtn.setTitle(L10n.connectNow, for: .normal)
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
}
